#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
rules_dir="$repo_dir/rules"
templates_dir="$repo_dir/templates"
rules_common_dir="$rules_dir/common"

show_help() {
    cat <<'EOF'
Usage: install-config.sh [options]

Installe ou regenere les fichiers de configuration des providers a partir des
templates de ce depot.

Options:
  --claude, -C   Installer la configuration Claude (defaut si aucune option)
  --gemini, -G   Installer la configuration Gemini
  --codex,  -X   Installer la configuration Codex
  --vibe,   -B   Installer la configuration Mistral Vibe
  --verify, -Y   Verifier l'installation existante sans rien ecrire
  --help,   -h   Afficher cette aide

Plusieurs options peuvent etre combinees dans un meme appel.
EOF
}

fail() {
    echo "$*" >&2
    exit 1
}

replace_repo_dir() {
    local escaped_repo_dir
    escaped_repo_dir=$(printf '%s' "$repo_dir" | sed 's/[&|\\]/\\&/g')
    sed "s|{{AGENTS_DIR}}|$escaped_repo_dir|g"
}

inline_rules() {
    local template_file=$1
    local line relative_path rule_file resolved_rule_file resolved_rules_dir

    resolved_rules_dir=$(cd "$rules_dir" && pwd -P)

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%$'\r'}
        if [[ $line =~ ^\{\{INCLUDE:([^}]*)\}\}$ ]]; then
            relative_path=${BASH_REMATCH[1]}
            [[ -n $relative_path && $relative_path != /* && $relative_path != *".."* ]] || \
                fail "{{INCLUDE:$relative_path}} invalide"

            rule_file="$rules_dir/$relative_path"
            [[ -f $rule_file ]] || fail "Rule introuvable pour {{INCLUDE:$relative_path}}"
            [[ ! -L $rule_file ]] || fail "{{INCLUDE:$relative_path}} est un lien symbolique : refuse"

            resolved_rule_file=$(cd "$(dirname "$rule_file")" && pwd -P)/$(basename "$rule_file")
            [[ $resolved_rule_file == "$resolved_rules_dir/"* ]] || \
                fail "{{INCLUDE:$relative_path}} sort du dossier rules/"

            cat "$resolved_rule_file"
        else
            printf '%s\n' "$line"
        fi
    done < "$template_file"
}

render_template() {
    local template_file=$1
    local target_file=$2
    local should_inline=$3
    local target_dir temporary_file

    [[ -f $template_file ]] || fail "Template introuvable: $template_file"
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"
    [[ ! -d $target_file && ! -L $target_file ]] || \
        fail "$target_file existe et n'est pas un fichier regulier : refuse d'ecraser"
    temporary_file=$(mktemp "$target_dir/.install-config.XXXXXX")

    if [[ $should_inline == true ]]; then
        if ! inline_rules "$template_file" | replace_repo_dir > "$temporary_file"; then
            rm -f "$temporary_file"
            return 1
        fi
    else
        if ! replace_repo_dir < "$template_file" > "$temporary_file"; then
            rm -f "$temporary_file"
            return 1
        fi
    fi

    mv "$temporary_file" "$target_file"
}

install_claude_rules_link() {
    local link_dir="$HOME/.claude/rules"
    local current_target

    mkdir -p "$(dirname "$link_dir")"
    if [[ -L $link_dir ]]; then
        current_target=$(readlink "$link_dir")
        if [[ $current_target == "$rules_common_dir" ]]; then
            return
        fi
        rm "$link_dir"
    elif [[ -e $link_dir ]]; then
        fail "$link_dir existe et n'est pas un lien : refuse d'ecraser"
    fi

    ln -s "$rules_common_dir" "$link_dir"
}

install_claude() {
    install_claude_rules_link
    render_template "$templates_dir/CLAUDE.template.md" "$HOME/.claude/CLAUDE.md" false
}

install_gemini() {
    render_template "$templates_dir/GEMINI.template.md" "$HOME/.gemini/GEMINI.md" true
}

install_codex() {
    render_template "$templates_dir/AGENTS.template.md" "$HOME/.codex/AGENTS.md" true
}

install_vibe() {
    render_template "$templates_dir/AGENTS.template.md" "$HOME/.vibe/AGENTS.md" true
}

verify_file() {
    local provider=$1
    local file=$2
    local template_file=$3
    local should_inline=$4
    local problem=0

    if [[ ! -f $template_file ]]; then
        echo "$provider : template absent ($template_file)" >&2
        return 1
    fi
    if [[ ! -f $file ]]; then
        echo "$provider : fichier absent ($file)" >&2
        return 1
    fi
    if [[ ! -s $file ]]; then
        echo "$provider : fichier vide ($file)" >&2
        return 1
    fi
    if grep -q '{{AGENTS_DIR}}\|{{INCLUDE:' "$file"; then
        echo "$provider : placeholder non substitue dans $file" >&2
        return 1
    fi
    if [[ $file -ot $template_file ]]; then
        echo "$provider : PERIME (anterieur a $(basename "$template_file"))" >&2
        problem=1
    fi
    if [[ $should_inline == true ]]; then
        local newer_rules
        if [[ ! -d $rules_dir ]]; then
            echo "$provider : dossier rules absent ($rules_dir)" >&2
            return 1
        fi
        if ! newer_rules=$(find "$rules_dir" -type f -newer "$file" -print); then
            echo "$provider : impossible de parcourir $rules_dir" >&2
            return 1
        fi
        if [[ -n $newer_rules ]]; then
            echo "$provider : PERIME (anterieur a une rule)" >&2
            problem=1
        fi
    fi

    if (( problem == 0 )); then
        echo "OK  $provider a jour ($file)"
    fi
    return "$problem"
}

verify_installation() {
    local problems=0
    local claude_link="$HOME/.claude/rules"
    local link_target

    if [[ ! -d $rules_common_dir || ! -L $claude_link || ! -d $claude_link ]]; then
        echo "Claude : jonction absente ou invalide ($claude_link)" >&2
        problems=1
    else
        link_target=$(readlink "$claude_link")
        if [[ $link_target != "$rules_common_dir" ]]; then
            echo "Claude : lien incorrect ($claude_link -> $link_target)" >&2
            problems=1
        else
            echo "OK  lien $claude_link -> $rules_common_dir"
        fi
    fi

    verify_file claude "$HOME/.claude/CLAUDE.md" "$templates_dir/CLAUDE.template.md" false || problems=1
    verify_file gemini "$HOME/.gemini/GEMINI.md" "$templates_dir/GEMINI.template.md" true || problems=1
    verify_file codex "$HOME/.codex/AGENTS.md" "$templates_dir/AGENTS.template.md" true || problems=1
    verify_file vibe "$HOME/.vibe/AGENTS.md" "$templates_dir/AGENTS.template.md" true || problems=1

    (( problems == 0 )) || return 1
}

targets=()
target_count=0
verify=false

while (( $# > 0 )); do
    case $1 in
        --claude|-C) targets+=(claude); ((target_count += 1)) ;;
        --gemini|-G) targets+=(gemini); ((target_count += 1)) ;;
        --codex|-X) targets+=(codex); ((target_count += 1)) ;;
        --vibe|-B) targets+=(vibe); ((target_count += 1)) ;;
        --verify|-Y) verify=true ;;
        --help|-h) show_help; exit 0 ;;
        *) fail "Argument inconnu: $1. Options valides: --claude, -C, --gemini, -G, --codex, -X, --vibe, -B, --verify, -Y, --help, -h" ;;
    esac
    shift
done

if (( target_count == 0 )) && [[ $verify == false ]]; then
    targets=(claude)
fi

for target in "${targets[@]}"; do
    case $target in
        claude) install_claude ;;
        gemini) install_gemini ;;
        codex) install_codex ;;
        vibe) install_vibe ;;
    esac
done

if [[ $verify == true ]]; then
    verify_installation
fi
