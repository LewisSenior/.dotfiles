---
name: vault-query
description: MUST load before ANY technical task, using ANY CLI tool, or answering ANY technical question. Search the vault for existing notes, preferences, and documentation FIRST.
compatibility: opencode
metadata:
  audience: developer
  workflow: research
---

## What I do

Before working on any technical topic, I search the Obsidian vault to find existing notes that may cover the topic. This ensures I'm using existing knowledge and avoiding duplicates.

## When to use me

Use this skill whenever:
- You need to find documentation about a tool, concept, or process
- You want to verify how something is already documented
- You're researching a technical topic
- You're about to explain or use something that might already have notes
- You need to understand what's already known before answering a question

## Vault structure

The vault at `~/brain` is organised by note type:

```
brain/
├── concepts/     # "What is X?" - theory, mental models, how things work
├── tools/        # "How do I use X?" - specific tools and technologies
├── patterns/     # Reusable techniques, workflows, design patterns
├── guides/       # Step-by-step procedural notes, runbooks, how-tos
├── exercises/    # Hands-on practice and exercises
├── journal/      # Daily notes, learning logs, reflections
└── _meta/templates/  # Note and journal templates
```

### Frontmatter taxonomy

- **type**: concept | tool | pattern | guide | exercise | reference
- **domain**: networking | systems | dev | security | cloud | devops | data | misc
- **level**: beginner | intermediate | advanced

## Workflow

1. **Search by folder first**: If you know the note type, search the matching folder directly:
   - Looking for a tool reference? Search `tools/`
   - Looking for a concept explanation? Search `concepts/`
   - Looking for exercises? Search `exercises/`
   - Looking for a pattern or technique? Search `patterns/`
   - Looking for a how-to or runbook? Search `guides/`

2. **Search broadly**: Use glob to find notes by filename patterns (e.g., `**/*tcpdump*`, `**/*networking*`) and grep to search within note contents

3. **Review existing notes**:
   - Read relevant notes to understand what's already documented
   - Note the confidence level in frontmatter to gauge reliability
   - Check the `last_reviewed` date for currency

4. **Decide next step**:
   - If good notes exist: Use the information and cite sources
   - If partial notes exist: Read them and update/expand as needed
   - If no notes exist: Load the vault-document skill to create one

## Important notes

- Always check the vault first before creating new documentation
- Pay attention to confidence levels -- low confidence notes may need verification
- Cross-reference multiple notes when available
- If you find relevant notes, mention them in your response
- Wiki-links always use kebab-case matching filenames: `[[linux-kernel]]` not `[[Linux Kernel]]`
