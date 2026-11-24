#!/usr/bin/env bash
# Tests for claude-sessions-save and claude-sessions-restore. These guard the
# promise that a reboot costs one command: every saved session comes back in
# its own place, and no session that is still running gets a second copy
# writing to the same transcript.
#
# Fake `claude` and `kitty` commands stand in for the real ones. The fake
# `claude agents --json` prints $FAKE_LIVE, and every other call is recorded,
# so no real session is touched. Run: bash tests/claude-sessions_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0
fail() { echo "  FAIL: $*" >&2; failures=$((failures + 1)); }

setup() {
  T="$(mktemp -d)"
  export HOME="$T/home" XDG_STATE_HOME="$T/state" CALLS="$T/calls"
  mkdir -p "$HOME/bin" "$T/work/a" "$T/work/b" "$T/work/c"
  install -m 755 "$SRC/private_dot_local/bin/executable_claude-sessions-save" "$HOME/bin/claude-sessions-save"
  install -m 755 "$SRC/private_dot_local/bin/executable_claude-sessions-restore" "$HOME/bin/claude-sessions-restore"
  export PATH="$HOME/bin:$PATH"
  : >"$CALLS"

  cat >"$HOME/bin/claude" <<'EOF'
#!/bin/sh
if [ "$1" = agents ] && [ "$2" = --json ]; then printf '%s\n' "$FAKE_LIVE"; exit 0; fi
echo "claude cwd=$PWD $*" >>"$CALLS"
EOF
  cat >"$HOME/bin/kitty" <<'EOF'
#!/bin/sh
echo "kitty $*" >>"$CALLS"
EOF
  chmod +x "$HOME/bin/claude" "$HOME/bin/kitty"
}
teardown() { rm -rf "$T"; }

session() { # kind sessionId cwd
  printf '{"kind":"%s","sessionId":"%s","cwd":"%s","name":"n-%s"}' "$1" "$2" "$3" "$2"
}

# --- save ---------------------------------------------------------------

test_save_writes_the_live_sessions() {
  setup
  export FAKE_LIVE="[$(session interactive i1 "$T/work/a")]"
  claude-sessions-save >/dev/null
  # Restore reads this file, so it must hold what `claude agents` reported.
  jq -e '.[0].sessionId == "i1"' "$XDG_STATE_HOME/claude-sessions/snapshot.json" >/dev/null \
    || fail "snapshot does not hold the live session"
  teardown
}

test_save_keeps_the_previous_snapshot() {
  setup
  export FAKE_LIVE="[$(session interactive i1 "$T/work/a")]"
  claude-sessions-save >/dev/null
  # A save run by mistake after a reboot sees no sessions. The list from
  # before the reboot must survive it.
  export FAKE_LIVE="[]"
  claude-sessions-save >/dev/null
  jq -e '.[0].sessionId == "i1"' "$XDG_STATE_HOME/claude-sessions/snapshot.prev.json" >/dev/null \
    || fail "previous snapshot was not kept"
  teardown
}

# --- restore ------------------------------------------------------------

save_snapshot() { # json
  mkdir -p "$XDG_STATE_HOME/claude-sessions"
  printf '%s\n' "$1" >"$XDG_STATE_HOME/claude-sessions/snapshot.json"
}

test_restore_opens_one_kitty_window_per_interactive_session() {
  setup
  save_snapshot "[$(session interactive i1 "$T/work/a"),$(session interactive i2 "$T/work/b")]"
  export FAKE_LIVE="[]"
  claude-sessions-restore >/dev/null
  # One OS window per session, started where the session lived, because
  # resume finds transcripts by project directory.
  grep -qxF "kitty --detach --directory $T/work/a claude --resume i1" "$CALLS" || fail "i1 window not opened in its cwd"
  grep -qxF "kitty --detach --directory $T/work/b claude --resume i2" "$CALLS" || fail "i2 window not opened in its cwd"
  teardown
}

test_restore_resumes_background_sessions_in_the_background() {
  setup
  save_snapshot "[$(session background b1 "$T/work/c")]"
  export FAKE_LIVE="[]"
  claude-sessions-restore >/dev/null
  # Background sessions had no window before, so they get none now.
  grep -qxF "claude cwd=$T/work/c --bg --resume b1" "$CALLS" || fail "b1 not resumed with --bg in its cwd"
  grep -q '^kitty' "$CALLS" && fail "a background session opened a window"
  teardown
}

test_restore_skips_sessions_that_are_still_running() {
  setup
  save_snapshot "[$(session interactive i1 "$T/work/a"),$(session background b1 "$T/work/c")]"
  export FAKE_LIVE="[$(session interactive i1 "$T/work/a"),$(session background b1 "$T/work/c")]"
  claude-sessions-restore >/dev/null
  # Two processes on one transcript would interleave their writes.
  [ -s "$CALLS" ] && fail "a running session was launched again: $(cat "$CALLS")"
  teardown
}

test_restore_skips_a_session_whose_directory_is_gone() {
  setup
  save_snapshot "[$(session interactive gone "$T/work/removed"),$(session interactive i1 "$T/work/a")]"
  export FAKE_LIVE="[]"
  # A removed worktree must not stop the other sessions from coming back.
  claude-sessions-restore >/dev/null 2>&1 || fail "restore failed on a missing directory"
  grep -q 'resume gone' "$CALLS" && fail "a session with a missing directory was launched"
  grep -q 'resume i1' "$CALLS" || fail "the other session was not restored"
  teardown
}

test_restore_dry_run_launches_nothing() {
  setup
  save_snapshot "[$(session interactive i1 "$T/work/a")]"
  export FAKE_LIVE="[]"
  out="$(claude-sessions-restore --dry-run)"
  # Dry run is how to check a snapshot before committing to many windows.
  [ -s "$CALLS" ] && fail "dry run launched: $(cat "$CALLS")"
  grep -q 'i1' <<<"$out" || fail "dry run did not list i1"
  teardown
}

test_restore_without_a_snapshot_fails() {
  setup
  export FAKE_LIVE="[]"
  # Restoring nothing in silence would hide a forgotten save.
  if claude-sessions-restore >/dev/null 2>&1; then fail "restore succeeded with no snapshot"; fi
  teardown
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
  echo "$t"
  "$t"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo "all tests passed"
