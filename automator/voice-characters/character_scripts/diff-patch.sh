#!/usr/bin/env bash
# Quickly create and apply diff patch to other scripts to keep slight changes in sync.
# Dependencies:
# - bash
# - diff (for generating unified diffs)
# - sed  (for normalizing diff headers)
# - patch (for applying/validating patches)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./diff-patch.sh diff <old-file> <new-file> > patch.diff
  ./diff-patch.sh patch <patch-file> <target-file> [more-target-files...]
  ./diff-patch.sh patch --dry-run <patch-file> <target-file> [more-target-files...]
  ./diff-patch.sh patch <patch-file> '*.sh'

Commands:
  diff   Generate a reusable unified patch from old-file -> new-file.
         Header paths are normalized to "a/file" and "b/file" so the
         resulting patch can be applied to similarly structured files
         regardless of original filenames.
  patch  Apply patch-file to one or more target files.
         Supports literal files and glob patterns (for example: '*.sh').
         Options:
           --dry-run, -n  Validate patch without modifying target-file.
EOF
}

require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "Error: ${label} not found: $path" >&2
    exit 1
  fi
}

cmd_diff() {
  if [[ $# -ne 2 ]]; then
    usage
    exit 1
  fi

  local old_file="$1"
  local new_file="$2"
  require_file "old file" "$old_file"
  require_file "new file" "$new_file"

  # Use git-style unified diff for stable patch format.
  # Then normalize file headers so filename differences do not matter.
  if ! diff -u "$old_file" "$new_file" | sed -E \
    -e "1s|^--- .*|--- a/file|" \
    -e "2s|^\\+\\+\\+ .*|+++ b/file|"; then
    status=$?
    # diff exits 1 when files differ (expected), >1 is a real error.
    if [[ ${status} -gt 1 ]]; then
      echo "Error: failed to generate diff." >&2
      exit "${status}"
    fi
  fi
}

cmd_patch() {
  local dry_run=0
  if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    dry_run=1
    shift
  fi

  if [[ $# -lt 2 ]]; then
    usage
    exit 1
  fi

  local patch_file="$1"
  shift
  require_file "patch file" "$patch_file"
  local self_name
  self_name="$(basename "$0")"

  local -a resolved_targets=()
  local arg=""
  local match=""
  for arg in "$@"; do
    # Expand wildcard patterns passed literally (for example: '*.sh').
    if [[ "$arg" == *[\*\?\[]* ]]; then
      local -a matches=()
      while IFS= read -r match; do
        matches+=("$match")
      done < <(compgen -G "$arg" || true)
      if [[ ${#matches[@]} -eq 0 ]]; then
        echo "Error: pattern matched no files: $arg" >&2
        exit 1
      fi
      resolved_targets+=("${matches[@]}")
    else
      resolved_targets+=("$arg")
    fi
  done

  local target_file=""
  for target_file in "${resolved_targets[@]}"; do
    if [[ "$(basename "$target_file")" == "$self_name" ]]; then
      echo "Skipping self file: $target_file" >&2
      continue
    fi
    require_file "target file" "$target_file"

    # --force applies even when RCS/SCCS checks are present.
    # --no-backup-if-mismatch avoids stray *.orig files on fuzz mismatches.
    if [[ $dry_run -eq 1 ]]; then
      patch --dry-run --force --no-backup-if-mismatch "$target_file" "$patch_file"
    else
      patch --force --no-backup-if-mismatch "$target_file" "$patch_file"
    fi
  done
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local command="$1"
  shift
  case "$command" in
    diff) cmd_diff "$@" ;;
    patch) cmd_patch "$@" ;;
    -h|--help|help) usage ;;
    *)
      echo "Error: unknown command: $command" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
