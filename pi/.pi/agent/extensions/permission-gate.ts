import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

const exec = promisify(execFile);

type Rule = { id: string; why: string; pattern: RegExp };
type ArgRule = Rule & { argv0: Set<string> };

const DENY: Rule[] = [
	{ id: "disk-write", why: "raw disk write", pattern: /\b(mkfs\S*|dd)\b[^|]*\bof=\/dev\// },
	{ id: "fork-bomb", why: "fork bomb", pattern: /:\(\)\s*\{.*\}\s*;\s*:/ },
	{ id: "rm-root", why: "rm -rf /", pattern: /\brm\s+(-\w*\s+)*(-\w*r\w*)\s+(-\w*\s+)*\/(\s|$)/ },
];

const ASK: Rule[] = [
	{ id: "rm-recursive", why: "recursive delete", pattern: /\brm\s+(-\w*[rR]\w*|--recursive)/ },
	{ id: "sudo", why: "privilege escalation", pattern: /\b(sudo|doas)\b/ },
	{ id: "chmod-777", why: "world-writable perms", pattern: /\b(chmod|chown)\b[^|]*\b777\b/ },
	{ id: "git-force-push", why: "force push", pattern: /\bgit\s+push\b.*(--force(?!-with-lease)|\s-f\b)/ },
	{ id: "git-destructive", why: "discards work", pattern: /\bgit\s+(reset\s+--hard|clean\s+-\w*[fd]|branch\s+-D)\b/ },
	{ id: "service-control", why: "service disruption", pattern: /\b(systemctl|service)\s+(stop|restart|disable|mask)\b/ },
	{ id: "process-kill", why: "kills processes", pattern: /\b(killall|pkill)\b|\bkill\s+-9\b/ },
	{ id: "pkg-remove", why: "removes packages", pattern: /\b(apt|apt-get|dnf|yum)\s+(remove|purge|autoremove)\b/ },
	{
		id: "routeros-write",
		why: "RouterOS config change",
		pattern: /\/(interface|ip|ppp|routing|system|queue|certificate)[/\s].*\b(set|remove|disable|reset-configuration|reboot)\b/,
	},
];

const ARG_ASK: ArgRule[] = [
	{
		id: "sql-destructive",
		why: "destructive SQL",
		pattern: /\b(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE?|DELETE\s+FROM)\b/i,
		argv0: new Set(["mysql", "mariadb", "psql", "sqlite3", "mysqldump", "clickhouse-client"]),
	},
	{
		id: "sql-unscoped-update",
		why: "UPDATE with no WHERE",
		pattern: /\bUPDATE\b(?![\s\S]*\bWHERE\b)/i,
		argv0: new Set(["mysql", "mariadb", "psql", "sqlite3", "clickhouse-client"]),
	},
];

const WRAPPERS = new Set(["eval", "sh", "bash", "zsh", "dash", "ksh", "env", "nohup", "timeout", "watch", "xargs", "sudo", "doas", "ssh"]);
const SENSITIVE_TARGETS = [/^\/etc\//, /^\/boot\//, /^\/usr\//, /^\/dev\/[sn]/, /^\/var\/lib\//, /\.env$/];
const PROTECTED_PATHS = [/\.env(\.|$)/, /(^|\/)\.git\//, /(^|\/)id_[a-z0-9]+$/i, /\.pem$|\.key$/i];

type Cmd = { argv0: string; bare: string; quoted: string[]; tokens: string[] };
type Finding = { id: string; why: string };

async function prettyPrint(script: string): Promise<string> {
	const dir = await mkdtemp(join(tmpdir(), "pi-gate-"));
	const file = join(dir, "s.sh");
	try {
		await writeFile(file, script);
		const { stdout } = await exec("bash", ["--pretty-print", file], { timeout: 5000, maxBuffer: 4 << 20 });
		return stdout;
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
}

function stripHeredocs(src: string): string {
	const lines = src.split("\n");
	const out: string[] = [];
	let i = 0;
	while (i < lines.length) {
		out.push(lines[i]);
		const m = /<<-?\s*(['"]?)([A-Za-z_]\w*)\1/.exec(lines[i]);
		i++;
		if (!m) continue;
		while (i < lines.length && lines[i].trim() !== m[2]) i++;
		if (i < lines.length) i++;
	}
	return out.join("\n");
}

function splitQuotes(seg: string): { bare: string; quoted: string[] } {
	let bare = "";
	const quoted: string[] = [];
	let i = 0;
	while (i < seg.length) {
		const c = seg[i];
		if (c === "\\") {
			bare += " ";
			i += 2;
			continue;
		}
		if (c === "'" || c === '"') {
			const end = seg.indexOf(c, i + 1);
			if (end === -1) {
				bare += " ";
				break;
			}
			quoted.push(seg.slice(i + 1, end));
			bare += " ";
			i = end + 1;
			continue;
		}
		bare += c;
		i++;
	}
	return { bare, quoted };
}

function toCommands(src: string): Cmd[] {
	return stripHeredocs(src)
		.split(/(?:\|\||&&|[;\n|&()]|\$\(|`|\{|\})+/)
		.map((s) => s.trim())
		.filter(Boolean)
		.map((seg) => {
			const { bare, quoted } = splitQuotes(seg);
			const all = bare.trim().split(/\s+/).filter(Boolean);
			let k = 0;
			while (k < all.length && (/^\w+=/.test(all[k]) || /^[<>]/.test(all[k]))) k++;
			return { argv0: all[k] ?? "", bare: bare.trim(), quoted, tokens: all.slice(k) };
		})
		.filter((c) => c.argv0);
}

function inspect(cmds: Cmd[], depth: number, found: Map<string, string>): void {
	for (const c of cmds) {
		for (const r of DENY) if (r.pattern.test(c.bare)) found.set(`deny:${r.id}`, r.why);
		for (const r of ASK) if (r.pattern.test(c.bare)) found.set(r.id, r.why);
		for (const r of ARG_ASK) {
			if (!r.argv0.has(c.argv0)) continue;
			if (r.pattern.test(c.bare) || c.quoted.some((q) => r.pattern.test(q))) found.set(r.id, r.why);
		}

		if (/^\$\{?\w+\}?$/.test(c.argv0) || c.argv0.startsWith("`")) {
			found.set("dynamic-argv0", "command name resolved at runtime");
		}
		if (/^(sh|bash|zsh|dash|ksh)$/.test(c.argv0) && c.tokens.length === 1 && c.quoted.length === 0) {
			found.set("pipe-to-shell", "executes piped input as shell code");
		}
		for (const m of c.bare.matchAll(/(?:^|\s)(?:\d+|&)?>>?\s*([^\s|;&<>]+)/g)) {
			if (SENSITIVE_TARGETS.some((p) => p.test(m[1]))) found.set("sensitive-redirect", `writes to ${m[1]}`);
		}

		if (depth < 3 && WRAPPERS.has(c.argv0)) {
			for (const q of c.quoted) if (/\s/.test(q)) inspect(toCommands(q), depth + 1, found);
		}
	}
}

async function analyze(command: string): Promise<Finding[]> {
	const found = new Map<string, string>();
	let normalized: string;
	try {
		normalized = await prettyPrint(command);
	} catch {
		// Unparseable by bash: fall back to raw-text matching so nothing is silently waved through.
		for (const r of [...DENY, ...ASK]) if (r.pattern.test(command)) found.set(r.id, r.why);
		return [...found].map(([id, why]) => ({ id, why }));
	}
	inspect(toCommands(normalized), 0, found);
	return [...found].map(([id, why]) => ({ id, why }));
}

export default function (pi: ExtensionAPI) {
	const allowedForSession = new Set<string>();

	pi.on("tool_call", async (event, ctx) => {
		if (isToolCallEventType("bash", event)) {
			const findings = await analyze(event.input.command);

			const denied = findings.filter((f) => f.id.startsWith("deny:"));
			if (denied.length > 0) {
				return { block: true, reason: `Denied by permission gate (${denied.map((f) => f.why).join(", ")})` };
			}

			const pending = findings.filter((f) => !allowedForSession.has(f.id));
			if (pending.length === 0) return undefined;

			const reasons = pending.map((f) => f.why).join(", ");
			if (!ctx.hasUI) {
				return { block: true, reason: `Needs approval (${reasons}) but no UI available` };
			}

			const ONCE = "Allow once";
			const SESSION = "Allow for this session";
			const choice = await ctx.ui.select(`Approve command?  [${reasons}]\n\n  ${event.input.command}`, [ONCE, SESSION, "Block"]);

			if (choice === SESSION) {
				for (const f of pending) allowedForSession.add(f.id);
				return undefined;
			}
			if (choice !== ONCE) return { block: true, reason: "Blocked by user" };
			return undefined;
		}

		if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
			const path = event.input.path;
			if (!PROTECTED_PATHS.some((p) => p.test(path))) return undefined;
			if (!ctx.hasUI) return { block: true, reason: `Protected path: ${path}` };
			if (!(await ctx.ui.confirm("Write to protected path?", path))) {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
