---
name: vault-documentation
description: Automatically document technical topics and CLI tools in the Obsidian vault using the note template
compatibility: opencode
metadata:
  audience: developer
  workflow: documentation
---

## What I do

When working on any technical topic, tool, or CLI command that isn't already documented in this vault, I automatically create a new note using the template system.

## When to use me

Use this skill whenever:
- You explain or use a CLI tool (e.g., `tcpdump`, `ss`, `iperf3`)
- You debug or troubleshoot a technical issue
- You learn a new concept, protocol, or system
- You work with any tool that should be documented for future reference
- You mention something worth remembering that doesn't have a note yet

## Workflow

1. **Check if note exists**: Before documenting, search for existing notes that may already cover the topic using grep/glob
2. **Use the template**: Copy from `~/brain/_meta/templates/note-template.md`
3. **Fill required fields**:
   - `title`: Human-readable title (Title Case)
   - `type`: concept | tool | pattern | process | reference
   - `domain`: networking | systems | dev | management | misc
   - `level`: beginner | intermediate | advanced
   - `tags`: lowercase tags as array
   - `confidence`: 0.0-1.0 after writing
   - `created`: today's date (YYYY-MM-DD)
   - `updated`: today's date
   - `last_reviewed`: today's date
   - `sources`: [] (can add URLs later)

4. **Write content sections**:
   - **Concise Summary**: 1-2 sentence overview
   - **Why This Matters**: Context and importance
   - **Core Concepts**: Key bullet points
   - **Tools / Tech**: Relevant tools or technologies used
   - **Examples**: Concrete examples with code blocks (use ```text for CLI commands)
   - **Failure Modes / Gotchas**: Common pitfalls
   - **In My Own Words** (Required): Personal understanding in blockquote >
   - **Related Notes**: Wiki-links to [[note-name]]
   - **Further Reading**: External references

5. **Naming**: Use kebab-case for filename (e.g., `tcp-troubleshooting-tools.md`)

6. **Link existing notes**: Add wiki-links in Related Notes section to connect knowledge

## Important notes

- Always use the template - don't skip sections
- Set confidence after writing based on your certainty
- Update dates in frontmatter when modifying existing notes
- Use `text` code blocks for shell commands that aren't valid syntax
- Cross-link liberally to build the knowledge graph
