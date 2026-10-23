#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

run_installer() {
    HOME="$test_home" bash "$repo_dir/install-config.sh" "$@"
}

run_installer --claude --gemini --codex --vibe

test -L "$test_home/.claude/rules"
test "$(readlink "$test_home/.claude/rules")" = "$repo_dir/rules/common"

test -f "$test_home/.claude/CLAUDE.md"
test -f "$test_home/.gemini/GEMINI.md"
test -f "$test_home/.codex/AGENTS.md"
test -f "$test_home/.vibe/AGENTS.md"
grep -F '# Global instructions for Gemini' "$test_home/.gemini/GEMINI.md" >/dev/null

if grep -R -E '\{\{AGENTS_DIR\}\}|\{\{INCLUDE:' "$test_home/.claude/CLAUDE.md" "$test_home/.gemini/GEMINI.md" \
    "$test_home/.codex/AGENTS.md" "$test_home/.vibe/AGENTS.md"; then
    echo 'placeholder non resolu' >&2
    exit 1
fi

run_installer --verify

rm "$test_home/.codex/AGENTS.md"
if run_installer --verify; then
    echo '--verify devait echouer quand un fichier genere manque' >&2
    exit 1
fi

before=$(find "$test_home" -mindepth 1 -print | sort)
if run_installer --unknown; then
    echo 'une option inconnue devait echouer' >&2
    exit 1
fi
after=$(find "$test_home" -mindepth 1 -print | sort)
test "$before" = "$after"

echo 'install-config.sh: tests passed'
