#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sync-agent-context.sh --source <path> --agent <claude|codex|copilot> [options]

Options:
  --target <path>     Repository root to update. Defaults to the current directory.
  --dry-run           Print planned actions without writing files.
  --skip-global       Do not update the global agent instruction file.
  --skip-repository   Do not update repository-local instruction files.
  -h, --help          Show this help.

Examples:
  scripts/sync-agent-context.sh --source ~/personal-code/claude-setup --agent claude --target .
  scripts/sync-agent-context.sh --source ~/personal-code/claude-setup --agent codex --target ~/work/app --dry-run
USAGE
}

expand_path() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

absolute_dir() {
  local path
  path="$(expand_path "$1")"
  mkdir -p "$path"
  (cd "$path" && pwd -P)
}

copy_file() {
  local source_file="$1"
  local target_file="$2"
  local display_source="${3:-$source_file}"
  local action

  if [ ! -f "$source_file" ]; then
    printf 'MISSING source %s\n' "$display_source"
    return 1
  fi

  if [ -f "$target_file" ] && cmp -s "$source_file" "$target_file"; then
    printf 'SKIP current %s\n' "$target_file"
    return 0
  fi

  if [ -f "$target_file" ]; then
    action="REPLACE"
  else
    action="CREATE"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN %s %s <- %s\n' "$action" "$target_file" "$display_source"
    return 0
  fi

  mkdir -p "$(dirname "$target_file")"
  cp "$source_file" "$target_file"
  printf '%s %s\n' "$action" "$target_file"
}

transform_references() {
  local source_file="$1"
  local output_file="$2"

  perl -0pe '
    s#\.claude/context/CLAUDE\.md#.agents/context/AGENTS.md#g;
    s#\.claude/styles/CLAUDE\.md#.agents/styles/AGENTS.md#g;
    s#\.claude/context/#.agents/context/#g;
    s#\.claude/skills/#.agents/skills/#g;
    s#\.claude/styles/#.agents/styles/#g;
  ' "$source_file" > "$output_file"
}

copy_agent_file() {
  local source_file="$1"
  local target_file="$2"
  local transform_refs="$3"
  local tmp_file

  if [ "$transform_refs" -eq 0 ]; then
    copy_file "$source_file" "$target_file"
    return
  fi

  tmp_file="$(mktemp)"
  transform_references "$source_file" "$tmp_file"
  copy_file "$tmp_file" "$target_file" "$source_file"
  rm -f "$tmp_file"
}

copy_tree() {
  local source_dir="$1"
  local target_dir="$2"
  local rename_claude_files="$3"
  local transform_refs="$4"
  local source_file rel target_rel

  if [ ! -d "$source_dir" ]; then
    printf 'MISSING source directory %s\n' "$source_dir"
    return 1
  fi

  find "$source_dir" -type f | while IFS= read -r source_file; do
    rel="${source_file#"$source_dir"/}"
    target_rel="$rel"
    if [ "$rename_claude_files" -eq 1 ]; then
      case "$target_rel" in
        CLAUDE.md) target_rel="AGENTS.md" ;;
        */CLAUDE.md) target_rel="${target_rel%CLAUDE.md}AGENTS.md" ;;
      esac
    fi
    copy_agent_file "$source_file" "$target_dir/$target_rel" "$transform_refs"
  done
}

SOURCE=""
AGENT=""
TARGET="$PWD"
DRY_RUN=0
SKIP_GLOBAL=0
SKIP_REPOSITORY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-global)
      SKIP_GLOBAL=1
      shift
      ;;
    --skip-repository)
      SKIP_REPOSITORY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$SOURCE" ] || [ -z "$AGENT" ]; then
  usage >&2
  exit 2
fi

case "$AGENT" in
  claude|codex|copilot) ;;
  *)
    printf 'Unsupported agent: %s\n' "$AGENT" >&2
    usage >&2
    exit 2
    ;;
esac

SOURCE="$(expand_path "$SOURCE")"
if [ ! -d "$SOURCE" ]; then
  printf 'Source directory does not exist: %s\n' "$SOURCE" >&2
  exit 1
fi
SOURCE="$(cd "$SOURCE" && pwd -P)"

if [ "$DRY_RUN" -eq 1 ]; then
  TARGET="$(expand_path "$TARGET")"
else
  TARGET="$(absolute_dir "$TARGET")"
fi

case "$AGENT" in
  claude)
    GLOBAL_TARGET="$HOME/.claude/CLAUDE.md"
    ROOT_TARGET="$TARGET/CLAUDE.md"
    CONTEXT_TARGET="$TARGET/.claude/context"
    SKILLS_TARGET="$TARGET/.claude/skills"
    STYLES_TARGET="$TARGET/.claude/styles"
    RENAME_CLAUDE_FILES=0
    ;;
  codex|copilot)
    if [ "$AGENT" = "codex" ]; then
      GLOBAL_TARGET="$HOME/.codex/AGENTS.md"
    else
      GLOBAL_TARGET="$HOME/.copilot/copilot-instructions.md"
    fi
    ROOT_TARGET="$TARGET/AGENTS.md"
    CONTEXT_TARGET="$TARGET/.agents/context"
    SKILLS_TARGET="$TARGET/.agents/skills"
    STYLES_TARGET="$TARGET/.agents/styles"
    RENAME_CLAUDE_FILES=1
    ;;
esac

if [ "$SKIP_GLOBAL" -eq 0 ]; then
  copy_file "$SOURCE/GLOBAL.md" "$GLOBAL_TARGET"
fi

if [ "$SKIP_REPOSITORY" -eq 0 ]; then
  copy_agent_file "$SOURCE/CLAUDE.md" "$ROOT_TARGET" "$RENAME_CLAUDE_FILES"
  copy_tree "$SOURCE/.claude/context" "$CONTEXT_TARGET" "$RENAME_CLAUDE_FILES" "$RENAME_CLAUDE_FILES"
  copy_tree "$SOURCE/.claude/skills" "$SKILLS_TARGET" 0 "$RENAME_CLAUDE_FILES"
  copy_tree "$SOURCE/.claude/styles" "$STYLES_TARGET" "$RENAME_CLAUDE_FILES" "$RENAME_CLAUDE_FILES"
  copy_file "$SOURCE/scripts/sync-agent-context.sh" "$TARGET/scripts/sync-agent-context.sh"

  if [ "$DRY_RUN" -eq 0 ]; then
    chmod +x "$TARGET/scripts/sync-agent-context.sh"
  fi
fi
