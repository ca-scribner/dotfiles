#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <origin-url> [--fork <fork-url>] [--dir <parent-dir>]
                        [--keep-on-failure]

Set up a bare git repo with worktrees for origin and fork.

Creates:
  <parent-dir>/<repo>/          bare repo
  <parent-dir>/<repo>/main/     worktree tracking origin/main
  <parent-dir>/<repo>/f-main/   worktree tracking f/main (local branch: f-main)

An unreachable fork is not fatal: setup continues and the f-<branch> worktree
is skipped. An unreachable origin is fatal.

If setup fails, <parent-dir>/<repo>/ is removed so a re-run starts clean. A
pre-existing destination is refused up front, so only directories this run
created are ever deleted.

Options:
  --fork <url>        Fork remote URL (default: git@github.com:ca-scribner/<repo>.git)
  --dir <path>        Parent directory (default: ./)
  --keep-on-failure   Leave the partially built repo behind for inspection
  -h, --help          Show this help
EOF
    exit "${1:-0}"
}

extract_repo_name() {
    local url="$1"
    # Handle both SSH (git@...:org/repo.git) and HTTPS (https://.../org/repo.git)
    basename "${url}" .git
}

# Reachability probe. Deliberately not --exit-code: an existing but empty repo
# has no refs, and that still counts as reachable.
remote_is_reachable() {
    git ls-remote --heads "$1" >/dev/null 2>&1
}

# Parse arguments
origin_url=""
fork_url=""
parent_dir="./"
keep_on_failure=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage 0 ;;
        --fork) fork_url="$2"; shift 2 ;;
        --dir) parent_dir="$2"; shift 2 ;;
        --keep-on-failure) keep_on_failure=true; shift ;;
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

if [[ ! -d "$parent_dir" ]]; then
    echo "Error: parent directory ${parent_dir} does not exist" >&2
    exit 1
fi

# Resolve to an absolute path: cleanup runs with the shell inside repo_dir, where
# a relative path would no longer resolve.
parent_dir="$(cd "$parent_dir" && pwd)"
repo_dir="${parent_dir}/${repo_name}"

# Refuse a pre-existing destination before doing any work, so cleanup can only
# ever remove a directory this run created.
if [[ -e "$repo_dir" ]]; then
    echo "Error: ${repo_dir} already exists" >&2
    exit 1
fi

# Set once the destination is ours to delete.
cleanup_dir=""

on_exit() {
    local status=$?
    [[ $status -eq 0 ]] && return
    [[ -n "$cleanup_dir" ]] || return

    if [[ "$keep_on_failure" == true ]]; then
        echo >&2
        echo "Setup failed (exit ${status}). Leaving ${cleanup_dir} in place (--keep-on-failure)." >&2
        return
    fi

    echo >&2
    echo "Setup failed (exit ${status}). Removing ${cleanup_dir}..." >&2
    cd "$parent_dir"
    rm -rf "$cleanup_dir"
}
trap on_exit EXIT

echo "Setting up ${repo_name}..."
echo "  origin: ${origin_url}"
echo "  fork:   ${fork_url}"
echo "  dir:    ${repo_dir}"
echo

echo "Checking remotes..."
if remote_is_reachable "$origin_url"; then
    echo "  origin: reachable    ${origin_url}"
else
    echo "  origin: UNREACHABLE  ${origin_url}"
    echo >&2
    echo "Error: origin must be reachable to clone. Nothing was created." >&2
    exit 1
fi

fork_reachable=false
if remote_is_reachable "$fork_url"; then
    fork_reachable=true
    echo "  fork:   reachable    ${fork_url}"
else
    echo "  fork:   UNREACHABLE  ${fork_url}"
    echo "          Continuing without it. Create the fork, then add its worktree with:"
    echo "            git-wt-add f-<branch> --from f/<branch>"
fi
echo

cleanup_dir="$repo_dir"
git clone --bare "$origin_url" "$repo_dir"
cd "$repo_dir"

# Bare clones don't fetch remote branches by default on future fetches.
# Fix the origin refspec so `git fetch origin` works as expected.
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

git remote add f "$fork_url"

git fetch origin
if [[ "$fork_reachable" == true ]]; then
    git fetch f
fi

# Determine the default branch
default_branch="$(git remote show origin | sed -n 's/.*HEAD branch: //p')"
if [[ -z "$default_branch" ]]; then
    default_branch="main"
    echo "Warning: could not detect default branch, assuming '${default_branch}'"
fi

# Bare clone creates a local branch for HEAD; remove it so worktree add -b can recreate
# it with proper tracking. Guarded rather than silenced, so a real failure to delete
# still aborts setup.
if git show-ref --verify --quiet "refs/heads/${default_branch}"; then
    git branch -D "${default_branch}"
fi
git worktree add "${default_branch}" -b "${default_branch}" "origin/${default_branch}"

if [[ "$fork_reachable" == true ]]; then
    if git show-ref --verify --quiet "refs/remotes/f/${default_branch}"; then
        mkdir -p f
        git worktree add "f-${default_branch}" -b "f-${default_branch}" "f/${default_branch}"
    else
        echo
        echo "Warning: fork has no '${default_branch}' branch; skipping f-${default_branch} worktree."
    fi
fi

echo
echo "Done. Worktrees:"
git worktree list
