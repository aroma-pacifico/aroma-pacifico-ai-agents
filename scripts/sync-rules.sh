#!/usr/bin/env bash
# ==============================================================================
# scripts/sync-rules.sh
# Canonical rule synchronization and drift checking for Aroma Pacífico
#
# Because the canonical repository (aroma-pacifico-ai-agents) is private and
# requires no external cross-repository token secrets, automated cross-repository
# CI synchronization is intentionally disabled.
#
# Drift checking and synchronization are executed locally by the lead agent or
# developer using this script and the local gh CLI credentials.
#
# Usage:
#   ./scripts/sync-rules.sh check
#       Compares all delivery repositories against the canonical rule set
#       and reports any drift.
#
#   ./scripts/sync-rules.sh apply <repo-path-or-name>
#       Copies the distributed rule set into the specified repository clone.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANONICAL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLONES_DIR="${CLONES_DIR:-/home/esteban/.local/state/agent-team/g01-clones}"

DELIVERY_REPOS=(
  "aroma-pacifico-architecture"
  "aroma-pacifico-diagrams"
  "aroma-pacifico-terraform-modules"
  "aroma-pacifico-infrastructure"
  "aroma-pacifico-design-system"
  "aroma-pacifico-presentation"
)

DISTRIBUTED_FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  ".claude/settings.json"
  "CONTRIBUTING.md"
  ".gitmessage"
  ".github/pull_request_template.md"
  ".github/workflows/pr-conventions.yml"
)

DISTRIBUTED_DIRS=(
  "standards"
  ".agents/skills"
)

resolve_repo_path() {
  local target="$1"

  if [ -d "$target" ]; then
    (cd "$target" && pwd)
    return 0
  fi

  if [ -d "${CLONES_DIR}/${target}" ]; then
    (cd "${CLONES_DIR}/${target}" && pwd)
    return 0
  fi

  if [ -d "${CLONES_DIR}/aroma-pacifico-${target}" ]; then
    (cd "${CLONES_DIR}/aroma-pacifico-${target}" && pwd)
    return 0
  fi

  if [ -d "${CANONICAL_ROOT}/../${target}" ]; then
    (cd "${CANONICAL_ROOT}/../${target}" && pwd)
    return 0
  fi

  if [ -d "${CANONICAL_ROOT}/../aroma-pacifico-${target}" ]; then
    (cd "${CANONICAL_ROOT}/../aroma-pacifico-${target}" && pwd)
    return 0
  fi

  echo "ERROR: Could not resolve repository path for: ${target}" >&2
  return 1
}

is_public_repo() {
  local repo_name="$1"
  if [ "$repo_name" = "aroma-pacifico-terraform-modules" ] || [ "$repo_name" = "terraform-modules" ]; then
    return 0
  fi
  return 1
}

apply_repo() {
  local target_input="$1"
  local target_path
  target_path="$(resolve_repo_path "$target_input")"
  local repo_name
  repo_name="$(basename "$target_path")"

  echo "Applying canonical rule set to: ${repo_name} (${target_path})"

  # Ensure destination directories exist
  mkdir -p "${target_path}/.claude"
  mkdir -p "${target_path}/.github/workflows"
  mkdir -p "${target_path}/standards"
  mkdir -p "${target_path}/.agents/skills"

  # Copy single files
  for f in "${DISTRIBUTED_FILES[@]}"; do
    local src_file="${CANONICAL_ROOT}/${f}"
    local dst_file="${target_path}/${f}"
    if [ ! -f "$src_file" ]; then
      echo "ERROR: Source file missing: ${src_file}" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$dst_file")"
    cp -p "$src_file" "$dst_file"
  done

  # Copy directory trees
  for d in "${DISTRIBUTED_DIRS[@]}"; do
    local src_dir="${CANONICAL_ROOT}/${d}"
    local dst_dir="${target_path}/${d}"
    if [ ! -d "$src_dir" ]; then
      echo "ERROR: Source directory missing: ${src_dir}" >&2
      exit 1
    fi
    rm -rf "$dst_dir"
    mkdir -p "$(dirname "$dst_dir")"
    cp -rp "$src_dir" "$dst_dir"
  done

  # Handle case statement: only for private delivery repositories
  local case_pdf_src="${CANONICAL_ROOT}/docs/case/case-statement.pdf"
  local case_pdf_dst="${target_path}/docs/case/case-statement.pdf"

  if is_public_repo "$repo_name"; then
    if [ -f "$case_pdf_dst" ]; then
      echo "Removing forbidden case-statement.pdf from public repository: ${repo_name}"
      rm -f "$case_pdf_dst"
      rmdir "${target_path}/docs/case" 2>/dev/null || true
      rmdir "${target_path}/docs" 2>/dev/null || true
    fi
  else
    if [ -f "$case_pdf_src" ]; then
      mkdir -p "${target_path}/docs/case"
      cp -p "$case_pdf_src" "$case_pdf_dst"
    else
      echo "WARNING: Canonical case statement not found at: ${case_pdf_src}" >&2
    fi
  fi

  echo "SUCCESS: Applied canonical rule set to ${repo_name}"
}

check_repo() {
  local target_path="$1"
  local repo_name
  repo_name="$(basename "$target_path")"
  local drift_count=0

  echo "Checking repository: ${repo_name}"

  # Check single files
  for f in "${DISTRIBUTED_FILES[@]}"; do
    local src_file="${CANONICAL_ROOT}/${f}"
    local dst_file="${target_path}/${f}"
    if [ ! -f "$dst_file" ]; then
      echo "  DRIFT: Missing file: ${f}"
      drift_count=$((drift_count + 1))
    elif ! cmp -s "$src_file" "$dst_file"; then
      echo "  DRIFT: File content mismatch: ${f}"
      drift_count=$((drift_count + 1))
    fi
  done

  # Check directory trees
  for d in "${DISTRIBUTED_DIRS[@]}"; do
    local src_dir="${CANONICAL_ROOT}/${d}"
    local dst_dir="${target_path}/${d}"
    if [ ! -d "$dst_dir" ]; then
      echo "  DRIFT: Missing directory: ${d}"
      drift_count=$((drift_count + 1))
    elif ! diff -rq "$src_dir" "$dst_dir" >/dev/null 2>&1; then
      echo "  DRIFT: Directory mismatch: ${d}"
      diff -rq "$src_dir" "$dst_dir" | sed 's/^/    /'
      drift_count=$((drift_count + 1))
    fi
  done

  # Check case statement rule
  local case_pdf_dst="${target_path}/docs/case/case-statement.pdf"
  local case_pdf_src="${CANONICAL_ROOT}/docs/case/case-statement.pdf"

  if is_public_repo "$repo_name"; then
    if [ -f "$case_pdf_dst" ]; then
      echo "  DRIFT: Forbidden case-statement.pdf present in public repository ${repo_name}"
      drift_count=$((drift_count + 1))
    fi
  else
    if [ ! -f "$case_pdf_dst" ]; then
      echo "  DRIFT: Missing docs/case/case-statement.pdf in private repository ${repo_name}"
      drift_count=$((drift_count + 1))
    elif ! cmp -s "$case_pdf_src" "$case_pdf_dst"; then
      echo "  DRIFT: Content mismatch in docs/case/case-statement.pdf"
      drift_count=$((drift_count + 1))
    fi
  fi

  if [ "$drift_count" -eq 0 ]; then
    echo "  STATUS: In sync (0 drift items)"
    return 0
  else
    echo "  STATUS: Drift detected (${drift_count} items)"
    return 1
  fi
}

check_all() {
  local total_drift=0
  echo "Running canonical rule drift check across all delivery repositories..."
  echo "Canonical root: ${CANONICAL_ROOT}"
  echo "Clones directory: ${CLONES_DIR}"
  echo ""

  for repo in "${DELIVERY_REPOS[@]}"; do
    local repo_path
    if ! repo_path="$(resolve_repo_path "$repo" 2>/dev/null)"; then
      echo "ERROR: Repository clone not found for: ${repo} under ${CLONES_DIR}"
      total_drift=$((total_drift + 1))
      continue
    fi

    if ! check_repo "$repo_path"; then
      total_drift=$((total_drift + 1))
    fi
    echo ""
  done

  if [ "$total_drift" -eq 0 ]; then
    echo "SUCCESS: All delivery repositories are in sync with canonical rules."
    return 0
  else
    echo "ERROR: Drift detected in ${total_drift} repositories."
    return 1
  fi
}

main() {
  if [ $# -lt 1 ]; then
    echo "Usage: $0 {check|apply <repo>}" >&2
    exit 1
  fi

  local command="$1"
  shift

  case "$command" in
    check)
      check_all
      ;;
    apply)
      if [ $# -lt 1 ]; then
        echo "Usage: $0 apply <repo-path-or-name>" >&2
        exit 1
      fi
      apply_repo "$1"
      ;;
    *)
      echo "Unknown command: ${command}" >&2
      echo "Usage: $0 {check|apply <repo>}" >&2
      exit 1
      ;;
  esac
}

main "$@"
