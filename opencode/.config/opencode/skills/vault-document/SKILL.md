---
name: vault-document
description: MUST load after completing ANY task where a new tool, concept, technique, or pattern was discussed. Document everything new to the vault.
compatibility: opencode
metadata:
  audience: developer
  workflow: documentation
---

## What I do

When something isn't already documented in the vault, I create a new note using the template system and place it in the correct folder.

## When to use me

ALWAYS use this skill:
- Before doing something you don't know how to do, query the vault first using vault-query
- After using any CLI tool for the first time in a session, **automatically invoke this skill** to document it
- When you explain or use a CLI tool
- When you debug or troubleshoot a technical issue
- When you learn a new concept, protocol, or system
- When you work with any tool that should be documented for future reference
- When you mention something worth remembering that doesn't have a note yet

## Folder Placement

Notes are organised by type into folders. Domain is tracked in frontmatter, NOT folders.

| If the note is about... | Put it in... | Example |
|---|---|---|
| A concept, theory, or "how does X work?" | `concepts/` | linux-kernel.md |
| A specific tool, CLI, or technology | `tools/` | terraform.md, systemd.md |
| A reusable technique or design pattern | `patterns/` | shell-pipe-patterns.md |
| A step-by-step procedure or how-to | `guides/` | deploy-to-aws.md |
| Hands-on practice exercises | `exercises/` | kernel-exercises.md |
| A daily log or reflection | `journal/` | 2026-02-21.md |

**Do NOT create notes in the vault root or invent new folders.**

## Workflow

1. **Check if note exists**: Search for existing notes using grep/glob before creating
2. **Determine the folder**: Use the placement table above
3. **Use the template**: Copy from `~/brain/_meta/templates/note-template.md` (or `journal-template.md` for journal entries)
4. **Fill required fields**:
   - `title`: Human-readable title (Title Case)
   - `type`: concept | tool | pattern | guide | exercise | reference
   - `domain`: networking | systems | dev | security | cloud | devops | data | misc
   - `level`: beginner | intermediate | advanced
   - `tags`: lowercase tags as array
   - `confidence`: 0.0-1.0 after writing
   - `created`: today's date (YYYY-MM-DD)
   - `updated`: today's date
   - `last_reviewed`: today's date
   - `sources`: [] (can add URLs later)

5. **Write content sections** (all required, in order):
   - **Concise Summary**: 1-2 sentence overview
   - **Why This Matters**: Context and importance
   - **Core Concepts**: Key bullet points
   - **Tools / Tech**: Relevant tools or technologies used
   - **Examples**: Concrete examples with code blocks (use ```text for CLI output)
   - **Failure Modes / Gotchas**: Common pitfalls
   - **In My Own Words** (Required): Personal understanding in blockquote >
   - **Related Notes**: Wiki-links to [[note-name]]
   - **Further Reading**: External references

6. **Naming**: Use kebab-case for filename (e.g., `tcp-troubleshooting-tools.md`)

7. **Wiki-links**: Always use kebab-case matching the filename: `[[linux-kernel]]` NOT `[[Linux Kernel]]`

8. **Link existing notes**: Add wiki-links in Related Notes section to connect knowledge

## Journal entries

Journal entries use a lightweight template from `~/brain/_meta/templates/journal-template.md`:

- Filename: `YYYY-MM-DD.md` in `journal/`
- Type: `journal`
- Sections: What I Worked On, What I Learned, Questions / Things to Explore

## Important notes

- Always use the template -- don't skip sections
- Set confidence after writing based on your certainty
- Update dates in frontmatter when modifying existing notes
- Use `text` code blocks for shell commands that aren't valid syntax
- Cross-link liberally to build the knowledge graph
- Never use Title Case in wiki-links -- always kebab-case
