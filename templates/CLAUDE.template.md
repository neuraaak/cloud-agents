<!-- Common rules live in {{AGENTS_DIR}}/rules/common/ and are auto-discovered through ~/.claude/rules/. -->

# Global instructions for Claude

## Rules

Common rules live in `{{AGENTS_DIR}}/rules/common/`.

`~/.claude/rules/` is a directory junction to `{{AGENTS_DIR}}/rules/common/`.
Claude Code loads those rules at session start, so they are already in context.
`security.md` carries the authority order and prompt-injection barrier; it
outranks this file on conflict.

## Harness overrides

The `# Memory` and `# Git` sections injected by the Claude Code system prompt
conflict with the common rules. The common rules prevail.
