import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { randomUUID } from "node:crypto";
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

// ---------------------------------------------------------------------------
// Headless policy
//
// Interactively, a flagged command prompts. Headlessly there is nobody to ask,
// and the original behaviour was to hard-deny everything — which makes an
// unattended agent run non-functional the moment it touches sudo, rm -r, a
// force push, destructive SQL, ...
//
// So when `ctx.hasUI` is false, each rule id resolves through a policy file to
// allow | deny | escalate. Two invariants:
//
//   * The DENY table is absolute in both modes and is never consulted here.
//   * A missing, unreadable or malformed policy falls back to `deny` for
//     everything, which is exactly the original behaviour. Failing closed means
//     a broken config cannot silently widen what an unattended agent may do.
//
// Interactive behaviour is deliberately untouched by all of this.
// ---------------------------------------------------------------------------

/**
 * Is there a HUMAN to ask — not merely a UI transport?
 *
 * `ctx.hasUI` answers the second question, not the first. pi's own docs are explicit
 * (docs/rpc.md:1164): "ctx.hasUI is true in RPC mode because the dialog and
 * fire-and-forget methods are functional via the extension UI sub-protocol. Use
 * ctx.mode === 'tui' to guard TUI-specific features."
 *
 * Gating on hasUI meant every shim-driven run took the INTERACTIVE branch, called
 * ctx.ui.select(), and blocked forever waiting for an answer no automated client was
 * going to send. It looked like the model stalling: the tool call never returned and
 * the run died on the caller's idle timeout with no error anywhere. Print mode
 * (`pi -p`) has no UI channel, so it took the headless path and worked — which is
 * exactly why testing only with `pi -p` hid the bug.
 */
function isInteractive(ctx: { mode?: string; hasUI?: boolean }): boolean {
	return ctx.mode === "tui";
}

type Verdict = "allow" | "deny" | "escalate";

type Judge = {
	// Off unless a URL is configured, so this file behaves exactly as it did before
	// L2b on any host that does not run the shim.
	url: string;
	secret: string;
	timeoutMs: number;
};

type Policy = {
	default: Verdict;
	rules: Record<string, Verdict>;
	protectedPaths: Verdict;
	requestDir: string;
	judge: Judge | null;
};

type Judgement = { verdict: Verdict; risk: number; rationale: string; legible: string };

/**
 * Ask the shim's judge to grade a specific command (L2b).
 *
 * Only ever consulted for calls the static policy resolved to `escalate` — a `deny`
 * is never reconsidered, and an `allow` needs no second opinion. So the judge can
 * only ever *narrow* an escalation into allow/deny, never widen a denial.
 *
 * Returns null on any failure, and the caller then parks the call: an unreachable
 * judge must not become an approval.
 */
async function askJudge(judge: Judge, command: string, findings: Finding[], cwd: string): Promise<Judgement | null> {
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(), judge.timeoutMs);
	try {
		const response = await fetch(judge.url, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				...(judge.secret ? { "X-Pishim-Gate-Secret": judge.secret } : {}),
			},
			body: JSON.stringify({ command, findings, cwd }),
			signal: controller.signal,
		});
		if (!response.ok) return null;
		const body = (await response.json()) as Partial<Judgement>;
		if (body.verdict !== "allow" && body.verdict !== "deny" && body.verdict !== "escalate") return null;
		return {
			verdict: body.verdict,
			risk: typeof body.risk === "number" ? body.risk : 100,
			rationale: typeof body.rationale === "string" ? body.rationale : "",
			legible: typeof body.legible === "string" ? body.legible : String(body.rationale ?? ""),
		};
	} catch {
		return null;
	} finally {
		clearTimeout(timer);
	}
}

const PI_DIR = join(homedir(), ".pi", "agent");

// $PI_GATE_POLICY wins, so the policy itself can live outside this (public) repo.
// A file enumerating what an unattended agent may do on this host is security
// posture, not configuration worth publishing — pi-chat-stack keeps it private
// and points here. With the variable unset and no local file, the gate stays
// fail-closed, which is the pre-L2a behaviour.
const POLICY_PATH = process.env.PI_GATE_POLICY || join(PI_DIR, "extensions", "gate-policy.json");

const CLOSED: Policy = {
	default: "deny",
	rules: {},
	protectedPaths: "deny",
	requestDir: join(PI_DIR, "gate-requests"),
	judge: null,
};

function asVerdict(value: unknown, fallback: Verdict): Verdict {
	return value === "allow" || value === "deny" || value === "escalate" ? value : fallback;
}

async function loadPolicy(): Promise<Policy> {
	// Read per decision rather than caching: flagged commands are rare, the file
	// is tiny, and it means an operator (or L2b) can change policy without
	// restarting a long-lived agent run.
	let raw: unknown;
	try {
		raw = JSON.parse(await readFile(POLICY_PATH, "utf8"));
	} catch {
		return CLOSED;
	}
	if (typeof raw !== "object" || raw === null) return CLOSED;

	const obj = raw as Record<string, unknown>;
	const rules: Record<string, Verdict> = {};
	if (typeof obj.rules === "object" && obj.rules !== null) {
		for (const [id, verdict] of Object.entries(obj.rules as Record<string, unknown>)) {
			const resolved = asVerdict(verdict, "deny");
			// An unrecognised verdict string is a typo, and a typo must not read as
			// "allow". asVerdict already floors it at deny; record it anyway.
			rules[id] = resolved;
		}
	}
	let judge: Judge | null = null;
	const rawJudge = obj.judge;
	if (typeof rawJudge === "object" && rawJudge !== null) {
		const j = rawJudge as Record<string, unknown>;
		// Enabled only by an explicit url. Absent => pre-L2b behaviour.
		if (j.enabled !== false && typeof j.url === "string" && j.url) {
			judge = {
				url: j.url,
				// Env wins when the policy leaves it blank, so the shared secret never has
				// to be committed alongside the policy. pi is spawned by the shim and
				// inherits its environment, so this is simply present.
				secret:
					typeof j.secret === "string" && j.secret
						? j.secret
						: process.env.PISHIM_GATE_SECRET || "",
				timeoutMs: typeof j.timeoutMs === "number" ? j.timeoutMs : 30000,
			};
		}
	}

	return {
		default: asVerdict(obj.default, "deny"),
		rules,
		protectedPaths: asVerdict(obj.protectedPaths, "deny"),
		requestDir: typeof obj.requestDir === "string" ? obj.requestDir.replace(/^~(?=\/)/, homedir()) : CLOSED.requestDir,
		judge,
	};
}

function verdictFor(id: string, policy: Policy): Verdict {
	return policy.rules[id] ?? policy.default;
}

/** Park an escalated call as a request the shim can surface. Returns its id. */
async function recordRequest(
	policy: Policy,
	kind: "bash" | "write",
	subject: string,
	findings: Finding[],
	judgement?: Judgement | null,
): Promise<string> {
	const id = randomUUID().slice(0, 8);
	try {
		await mkdir(policy.requestDir, { recursive: true, mode: 0o700 });
		await writeFile(
			join(policy.requestDir, `${id}.json`),
			JSON.stringify(
				{
					id,
					createdAt: new Date().toISOString(),
					kind,
					subject,
					cwd: process.cwd(),
					findings,
					judge: judgement ? { risk: judgement.risk, rationale: judgement.rationale } : null,
					state: "pending",
				},
				null,
				2,
			),
			// The subject may contain a secret (`mysql -pPASSWORD ...`). Owner-only.
			{ mode: 0o600 },
		);
	} catch {
		// A request we cannot record is still a blocked call — never let a failed
		// write turn an escalation into an allow.
	}
	return id;
}

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
			if (!isInteractive(ctx)) {
				const policy = await loadPolicy();
				const verdicts = pending.map((f) => ({ ...f, verdict: verdictFor(f.id, policy) }));

				// Most restrictive wins: one deny blocks the call regardless of what
				// else it tripped.
				const blocked = verdicts.filter((v) => v.verdict === "deny");
				if (blocked.length > 0) {
					return {
						block: true,
						reason: `Blocked by headless policy (${blocked.map((v) => `${v.why} [${v.id}]`).join(", ")})`,
					};
				}

				const escalated = verdicts.filter((v) => v.verdict === "escalate");
				if (escalated.length > 0) {
					const why = escalated.map((v) => `${v.why} [${v.id}]`).join(", ");

					// L2b: grade the specific command. Tiered rules are coarse —
					// `rm -rf ./build` and `rm -rf ~/photos` trip the same rule.
					let judgement: Judgement | null = null;
					if (policy.judge) {
						judgement = await askJudge(policy.judge, event.input.command, escalated, process.cwd());
					}

					if (judgement?.verdict === "allow") {
						return undefined;
					}
					if (judgement?.verdict === "deny") {
						return { block: true, reason: `Blocked by judge (${why}) — ${judgement.legible}` };
					}

					// No judge, judge unreachable, or judge said escalate: park it. An
					// unreachable judge must never become an approval.
					const id = await recordRequest(policy, "bash", event.input.command, escalated, judgement);
					const detail = judgement ? ` — ${judgement.legible}` : "";
					return {
						block: true,
						reason: `Escalated for approval, request ${id} (${why}). Not run.${detail}`,
					};
				}

				// Everything pending is explicitly allowed by policy.
				return undefined;
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
			if (!isInteractive(ctx)) {
				const policy = await loadPolicy();
				if (policy.protectedPaths === "allow") return undefined;
				if (policy.protectedPaths === "escalate") {
					const finding = { id: "protected-path", why: `write to ${path}` };
					const id = await recordRequest(policy, "write", path, [finding]);
					return { block: true, reason: `Escalated for approval, request ${id} (protected path: ${path}). Not written.` };
				}
				return { block: true, reason: `Protected path: ${path}` };
			}
			if (!(await ctx.ui.confirm("Write to protected path?", path))) {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
