#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <origin-url> [--fork <fork-url>] [--dir <parent-dir>]

Set up a bare git repo with worktrees for origin and fork.

Creates:
  <parent-dir>/<repo>/          bare repo
  <parent-dir>/<repo>/main/     worktree tracking origin/main
  <parent-dir>/<repo>/f-main/   worktree tracking f/main (local branch: f-main)

Options:
  --fork <url>   Fork remote URL (default: git@github.com:ca-scribner/<repo>.git)
  --dir <path>   Parent directory (default: ./)
  -h, --help     Show this help
EOF
    exit "${1:-0}"
}

extract_repo_name() {
    local url="$1"
    # Handle both SSH (git@...:org/repo.git) and HTTPS (https://.../org/repo.git)
    basename "${url}" .git
}

# Parse arguments
origin_url=""
fork_url=""
parent_dir="./"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage 0 ;;
        --fork) fork_url="$2"; shift 2 ;;
        --dir) parent_dir="$2"; shift 2 ;;
        -*)
            echo "Unknown option: $1" >&2
            usage 1
            ;;
        *)
            if [[ -z "$origin_url" ]]; then
                origin_url="$1"; shift
            else
                echo "Unexpected argument: $1" >&2
                usage 1
            fi
            ;;
    esac
done

if [[ -z "$origin_url" ]]; then
    echo "Error: origin URL is required" >&2
    usage 1
fi

repo_name="$(extract_repo_name "$origin_url")"

if [[ -z "$fork_url" ]]; then
    fork_url="git@github.com:ca-scribner/${repo_name}.git"
fi

repo_dir="${parent_dir}/${repo_name}"

if [[ -d "$repo_dir" ]]; then
    echo "Error: ${repo_dir} already exists" >&2
    exit 1
fi

echo "Setting up ${repo_name}..."
echo "  origin: ${origin_url}"
echo "  fork:   ${fork_url}"
echo "  dir:    ${repo_dir}"
echo

git clone --bare "$origin_url" "$repo_dir"
cd "$repo_dir"

# Bare clones don't fetch remote branches by default on future fetches.
# Fix the origin refspec so `git fetch origin` works as expected.
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

git remote add f "$fork_url"
git fetch --all

# Determine the default branch
default_branch="$(git remote show origin | sed -n 's/.*HEAD branch: //p')"
if [[ -z "$default_branch" ]]; then
    default_branch="main"
    echo "Warning: could not detect default branch, assuming '${default_branch}'"
fi

# Bare clone creates a local branch for HEAD; remove it so worktree add -b can recreate
# it with proper tracking.
git branch -D "${default_branch}" 2>/dev/null || true
git worktree add "${default_branch}" -b "${default_branch}" "origin/${default_branch}"
mkdir -p f
git worktree add "f-${default_branch}" -b "f-${default_branch}" "f/${default_branch}"

echo
echo "Done. Worktrees:"
git worktree list
