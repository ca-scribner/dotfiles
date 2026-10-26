#!/usr/bin/env bash
# Tests for sign-on-push: git-sign-unpushed, the global pre-push hook, and the
# `git spush` alias. Agents commit unsigned and sign at push time, so these
# tests guard the promise that nothing unsigned reaches a remote and that
# signing never changes the content of a commit.
#
# A fake x509 signer stands in for gitsign, so the tests need no network and
# open no browser. Run: bash tests/git-sign-on-push_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0
fail() { echo "  FAIL: $*" >&2; failures=$((failures + 1)); }

# setup builds an isolated HOME with the real dotfiles gitconfig, the hook and
# the script installed the way chezmoi would install them, plus a bare remote
# and a clone with one pushed commit.
setup() {
  T="$(mktemp -d)"
  export HOME="$T/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/home/.gitconfig"
  unset GIT_CONFIG_COUNT GITSIGN_CREDENTIAL_CACHE
  mkdir -p "$HOME/bin" "$HOME/hooks"
  install -m 755 "$SRC/private_dot_local/bin/executable_git-sign-unpushed" "$HOME/bin/git-sign-unpushed"
  install -m 755 "$SRC/dot_config/git/hooks/executable_pre-push" "$HOME/hooks/pre-push"
  export PATH="$HOME/bin:$PATH"

  # The fake signer records each call, so tests can assert when a login
  # (one signer call) would and would not happen.
  cat >"$HOME/bin/fake-signer" <<'EOF'
#!/bin/sh
cat >/dev/null
echo call >>"$HOME/signer-calls"
echo "[GNUPG:] SIG_CREATED " >&2
printf -- '-----BEGIN SIGNED MESSAGE-----\nfake\n-----END SIGNED MESSAGE-----\n'
EOF
  chmod +x "$HOME/bin/fake-signer"
  : >"$HOME/signer-calls"

  cat >"$GIT_CONFIG_GLOBAL" <<EOF
[include]
	path = $SRC/dot_gitconfig
[gpg "x509"]
	program = $HOME/bin/fake-signer
[core]
	hooksPath = $HOME/hooks
	pager = cat
[user]
	email = test@example.com
	name = Test User
EOF

  git init -q --bare "$T/remote.git"
  git clone -q "$T/remote.git" "$T/work" 2>/dev/null
  cd "$T/work"
  signed_commit "base"
  git push -q origin HEAD:refs/heads/main
  : >"$HOME/signer-calls"
}

teardown() { cd /; rm -rf "$T"; }

# commit makes an agent-style commit: unsigned, as agent sessions configure it.
commit() {
  echo "$1" >>"${2:-file}"
  git add "${2:-file}"
  git -c commit.gpgsign=false commit -q -m "$1"
}

signed_commit() {
  echo "$1" >>file
  git add file
  git commit -q -S -m "$1"
}

is_signed() { git cat-file commit "$1" | sed '/^$/q' | grep -q '^gpgsig '; }
signer_calls() { wc -l <"$HOME/signer-calls" | tr -d ' '; }

# Fingerprint of everything that must survive re-signing: tree, authorship,
# committer and message. Parent ids are left out because re-signing changes them.
content() { git log --format='%T|%an|%ae|%ad|%cn|%ce|%cd|%B' --date=raw "$@"; }

run() {
  local name="$1"
  echo "- $name"
  setup
  # set -e is ignored in a subshell whose status is tested, so capture it instead.
  set +e; ( set -e; "$name" ); local rc=$?; set -e
  [ "$rc" = 0 ] || fail "$name"
  teardown
}

# --- git-sign-unpushed ---

test_signs_unpushed_commits_without_changing_their_content() {
  commit a; commit b
  local before; before="$(content origin/main..HEAD)"
  git sign-unpushed
  for c in $(git rev-list origin/main..HEAD); do is_signed "$c" || { echo "unsigned $c"; return 1; }; done
  [ "$(content origin/main..HEAD)" = "$before" ] || { echo "content changed"; return 1; }
}

test_leaves_pushed_commits_alone_so_no_force_push_is_needed() {
  local pushed; pushed="$(git rev-parse origin/main)"
  commit a
  git sign-unpushed
  [ "$(git rev-parse HEAD~1)" = "$pushed" ]
}

test_keeps_already_signed_commits_so_their_ids_stay_stable() {
  signed_commit a
  local signed; signed="$(git rev-parse HEAD)"
  commit b
  git sign-unpushed
  [ "$(git rev-parse HEAD~1)" = "$signed" ] && is_signed HEAD
}

test_resigns_signed_commits_that_sit_on_top_of_unsigned_ones() {
  # Rewriting the unsigned parent changes the child's id, so the child needs a new signature too.
  commit a; signed_commit b
  git sign-unpushed
  is_signed HEAD~1 && is_signed HEAD
}

test_does_nothing_when_all_commits_are_signed_so_no_login_happens() {
  signed_commit a
  local head; head="$(git rev-parse HEAD)"
  : >"$HOME/signer-calls"
  git sign-unpushed
  [ "$(git rev-parse HEAD)" = "$head" ] && [ "$(signer_calls)" = 0 ]
}

test_keeps_merge_structure() {
  git switch -q -c side; commit side side-file
  git switch -q -; commit mainline
  git -c commit.gpgsign=false merge -q --no-edit side
  local before; before="$(content --topo-order origin/main..HEAD)"
  git sign-unpushed
  [ "$(git rev-list --count --merges origin/main..HEAD)" = 1 ] || { echo "merge lost"; return 1; }
  for c in $(git rev-list origin/main..HEAD); do is_signed "$c" || { echo "unsigned $c"; return 1; }; done
  [ "$(content --topo-order origin/main..HEAD)" = "$before" ]
}

test_leaves_uncommitted_work_untouched() {
  commit a
  echo dirty >>file; echo new >untracked; git add -N untracked
  local status; status="$(git status --porcelain)"
  git sign-unpushed
  [ "$(git status --porcelain)" = "$status" ] && grep -q dirty file
}

# --- pre-push hook ---

test_hook_blocks_unsigned_commits_and_says_how_to_fix_it() {
  commit a
  local out
  if out="$(git push origin HEAD:refs/heads/feature 2>&1)"; then echo "push succeeded"; return 1; fi
  grep -q 'git spush' <<<"$out" && grep -q -- '--no-verify' <<<"$out" && grep -q "$(git rev-parse --short HEAD)" <<<"$out"
}

test_hook_allows_signed_commits() {
  signed_commit a
  git push -q origin HEAD:refs/heads/feature
}

test_hook_allows_branch_deletion() {
  signed_commit a
  git push -q origin HEAD:refs/heads/feature
  git push -q origin :refs/heads/feature
}

test_hook_still_runs_the_repo_own_pre_push_hook() {
  # core.hooksPath hides .git/hooks, so the global hook must chain to it.
  signed_commit a
  printf '#!/bin/sh\necho repo-hook-ran >&2\nexit 1\n' >.git/hooks/pre-push
  chmod +x .git/hooks/pre-push
  local out
  if out="$(git push origin HEAD:refs/heads/feature 2>&1)"; then echo "repo hook ignored"; return 1; fi
  grep -q repo-hook-ran <<<"$out"
}

# --- git spush alias ---

test_spush_signs_then_pushes_agent_commits() {
  commit a; commit b
  git spush -q origin HEAD:refs/heads/feature
  for c in $(git rev-list origin/main..origin/feature); do is_signed "$c" || return 1; done
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/feature)" ]
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do run "$t"; done
if [ "$failures" -gt 0 ]; then echo "$failures failed"; exit 1; fi
echo "all passed"
