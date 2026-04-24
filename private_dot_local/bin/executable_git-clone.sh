#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# git-clone.sh
#
# Clone a Git repository from either a local path or a remote URL.
#
# Usage:
#   ./git-clone.sh <repo_path_or_url> <target_path>
#
# Behavior:
#   - If <repo_path_or_url> is a path to a local Git repository:
#       * The script performs a local clone using `git clone <path> <clone_path>`.
#       * If the source repository has a remote named "origin",
#         the script updates the new clone’s "origin" remote to point to the same
#         remote URL as the source repository.
#       * If the source repository has no "origin" remote, the clone’s "origin"
#         remains unchanged (it will still point to the local source path).
#
#   - If <repo_path_or_url> is a remote URL (e.g. https://..., git@..., etc.):
#       * The script performs a normal remote clone and does not modify the
#         clone’s "origin" remote.
#
# Example:
#   ./git-clone.sh ~/projects/foo ./foo-clone
#   ./git-clone.sh https://github.com/example/foo.git ./foo-clone
#
# -----------------------------------------------------------------------------

SOURCE="$1"
TARGET_PATH="$2"


echo "Cloning '$SOURCE' to '$TARGET_PATH'"
git clone "$SOURCE" "$TARGET_PATH"

# If SOURCE is a local directory that has a remote/origin, update TARGET to
# use that same remote
# redirect error to /dev/null so its always silent
# this will return REMOTE=empty if it hits an error
REMOTE_URL=$(git -C $SOURCE remote get-url origin 2>/dev/null)
if [[ -n "$REMOTE_URL" ]]; then
	git -C "$TARGET_PATH" remote set-url origin "$REMOTE_URL"
    echo "updated target's remote/origin to source's remote/origin: $REMOTE_URL"
fi

cd $TARGET_PATH
