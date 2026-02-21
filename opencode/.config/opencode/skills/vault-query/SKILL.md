---
name: vault-query
description: Query the Obsidian vault to find existing documentation, verify information, or check if topics are already documented
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

## Workflow

1. **Locate the vault**: The vault is at `~/brain` (or wherever `~/brain` points)

2. **Search for relevant notes**:
   - Use glob to find notes by filename patterns (e.g., `**/*tcpdump*`, `**/*networking*`)
   - Use grep to search within note contents
   - Check the `_meta/templates/` folder for available templates

3. **Review existing notes**:
   - Read relevant notes to understand what's already documented
   - Note the confidence level in frontmatter to gauge reliability
   - Check the "last_reviewed" date for currency

4. **Decide next step**:
   - If good notes exist: Use the information and cite sources
   - If partial notes exist: Read them and update/expand as needed
   - If no notes exist: Load the vault-document skill to create one

## Important notes

- Always check the vault first before creating new documentation
- Pay attention to confidence levels - low confidence notes may need verification
- Cross-reference multiple notes when available
- If you find relevant notes, mention them in your response
