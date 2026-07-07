#!/usr/bin/env bash
# =============================================================================
# verifier-daemon.sh — Background file watcher for standard compliance
# =============================================================================
#
# Watches source files for changes and runs verifiers automatically.
# Reports violations in real-time to a log file.
#
# Usage:
#   verifier-daemon.sh start    # Start daemon in background
#   verifier-daemon.sh stop     # Stop daemon
#   verifier-daemon.sh status   # Show daemon status
#   verifier-daemon.sh log      # Show recent violations
#   verifier-daemon.sh run      # Run verifiers once (foreground)
#
# Requires: inotify-tools (inotifywait)
# Fallback: polling mode if inotifywait not available
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_FILE="$SCRIPT_DIR/.verifier-daemon.pid"
LOG_FILE="$SCRIPT_DIR/.verifier-daemon.log"
LOCK_FILE="$SCRIPT_DIR/.verifier-daemon.lock"

# Directories to watch
WATCH_DIRS=(
  "$REPO_ROOT/src"
  "$REPO_ROOT/standards/standards"
  "$REPO_ROOT/standards/templates"
  "$REPO_ROOT/guard/rules"
  "$REPO_ROOT/skills"
)

# File patterns to watch
WATCH_PATTERNS="*.ts,*.tsx,*.js,*.md,*.sh"

# Polling interval (seconds) — used when inotifywait is not available
POLL_INTERVAL=10

# Cooldown between runs (seconds) — prevent overlapping verifier runs
COOLDOWN=5

# Max log size (bytes) before rotation
MAX_LOG_SIZE=1048576  # 1MB

# =============================================================================
# Helpers
# =============================================================================

log() {
  local level="$1"
  shift
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] [$level] $*" >> "$LOG_FILE"
}

logViolation() {
  local check="$1"
  local detail="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] [VIOLATION] $check: $detail" >> "$LOG_FILE"
  # Also write to stderr for immediate visibility
  echo "[daemon] VIOLATION: $check — $detail" >&2
}

rotateLog() {
  if [[ -f "$LOG_FILE" ]]; then
    local size
    size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    if (( size > MAX_LOG_SIZE )); then
      mv "$LOG_FILE" "${LOG_FILE}.1"
      log INFO "Log rotated (exceeded ${MAX_LOG_SIZE} bytes)"
    fi
  fi
}

# =============================================================================
# Verifier runner
# =============================================================================

runVerifiers() {
  local start_time
  start_time=$(date +%s)
  
  log INFO "=== Verifier run started ==="
  
  local violations=0
  
  # 1. verify-standards.js (content-level, fast)
  if [[ -f "$REPO_ROOT/standards/scripts/verify-standards.js" ]]; then
    local output
    output=$(cd "$REPO_ROOT" && node standards/scripts/verify-standards.js 2>&1) || true
    if echo "$output" | grep -q "\[FAIL\]"; then
      local fail_count
      fail_count=$(echo "$output" | grep -c "\[FAIL\]" || true)
      violations=$((violations + fail_count))
      logViolation "verify-standards" "$fail_count violation(s)"
      echo "$output" | grep "\[FAIL\]" | while read -r line; do
        logViolation "verify-standards" "$line"
      done
    else
      log INFO "verify-standards: PASS"
    fi
  fi
  
  # 2. verify-id-graph.js (cross-repo structural)
  if [[ -f "$REPO_ROOT/standards/scripts/verify-id-graph.js" ]]; then
    local output
    output=$(cd "$REPO_ROOT" && node standards/scripts/verify-id-graph.js 2>&1) || true
    if echo "$output" | grep -q "FAIL"; then
      local fail_count
      fail_count=$(echo "$output" | grep -c "FAIL" || true)
      violations=$((violations + fail_count))
      logViolation "verify-id-graph" "$fail_count HARD violation(s)"
    else
      log INFO "verify-id-graph: PASS"
    fi
  fi
  
  # 3. verify-skills.js (skills-side format)
  if [[ -f "$REPO_ROOT/standards/scripts/verify-skills.js" ]]; then
    local output
    output=$(cd "$REPO_ROOT" && node standards/scripts/verify-skills.js 2>&1) || true
    if echo "$output" | grep -q "\[FAIL\]"; then
      local fail_count
      fail_count=$(echo "$output" | grep -c "\[FAIL\]" || true)
      violations=$((violations + fail_count))
      logViolation "verify-skills" "$fail_count violation(s)"
    else
      log INFO "verify-skills: PASS"
    fi
  fi
  
  # 4. line-count-check.sh (SOFT — advisory only)
  if [[ -f "$REPO_ROOT/guard/scripts/line-count-check.sh" ]]; then
    local output
    output=$(cd "$REPO_ROOT" && bash guard/scripts/line-count-check.sh 2>&1) || true
    if echo "$output" | grep -q "WARN"; then
      log INFO "line-count: advisory warnings (SOFT)"
    else
      log INFO "line-count: PASS"
    fi
  fi
  
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  if (( violations > 0 )); then
    log WARNING "=== Verifier run: $violations violation(s) in ${duration}s ==="
  else
    log INFO "=== Verifier run: ALL PASS in ${duration}s ==="
  fi
  
  return $violations
}

# =============================================================================
# Daemon (inotifywait mode)
# =============================================================================

runInotifyDaemon() {
  log INFO "Starting inotifywait daemon (PID $$)"
  
  # Build inotifywait command
  local inotify_args=()
  for dir in "${WATCH_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      inotify_args+=("$dir")
    fi
  done
  
  if (( ${#inotify_args[@]} == 0 )); then
    log WARNING "No watch directories found, falling back to polling"
    runPollingDaemon
    return
  fi
  
  # Initial run
  runVerifiers || true
  
  # Watch for changes
  while true; do
    # Wait for file changes (modify, create, delete)
    inotifywait -r -q \
      --exclude '(\.git|node_modules|_snapshots|\.log$)' \
      -e modify -e create -e delete \
      "${inotify_args[@]}" 2>/dev/null || break
    
    # Cooldown — skip if too soon after last run
    sleep "$COOLDOWN"
    
    # Rotate log if needed
    rotateLog
    
    # Run verifiers
    runVerifiers || true
  done
  
  log WARNING "inotifywait exited unexpectedly"
}

# =============================================================================
# Daemon (polling mode — fallback)
# =============================================================================

runPollingDaemon() {
  log INFO "Starting polling daemon (PID $$, interval=${POLL_INTERVAL}s)"
  
  # Initial run
  runVerifiers || true
  
  # Poll loop
  while true; do
    sleep "$POLL_INTERVAL"
    
    # Check if any watched files changed since last check
    local changed=false
    for dir in "${WATCH_DIRS[@]}"; do
      if [[ -d "$dir" ]]; then
        if find "$dir" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.md" -o -name "*.sh" \
          -newer "$LOCK_FILE" 2>/dev/null | head -1 | grep -q .; then
          changed=true
          break
        fi
      fi
    done
    
    if $changed; then
      rotateLog
      touch "$LOCK_FILE"
      runVerifiers || true
    fi
  done
}

# =============================================================================
# Control commands
# =============================================================================

startDaemon() {
  if [[ -f "$PID_FILE" ]]; then
    local old_pid
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "[daemon] Already running (PID $old_pid)"
      return 1
    fi
    rm -f "$PID_FILE"
  fi
  
  touch "$LOCK_FILE"
  log INFO "Starting verifier daemon..."
  
  # Detect inotifywait availability
  if command -v inotifywait >/dev/null 2>&1; then
    log INFO "Using inotifywait mode"
    nohup bash "$0" _run_inotify >> "$LOG_FILE" 2>&1 &
  else
    log INFO "inotifywait not available, using polling mode"
    nohup bash "$0" _run_polling >> "$LOG_FILE" 2>&1 &
  fi
  
  local pid=$!
  echo "$pid" > "$PID_FILE"
  
  # Wait a moment and verify it started
  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    echo "[daemon] Started (PID $pid)"
    log INFO "Daemon started (PID $pid)"
  else
    echo "[daemon] FAILED to start — check $LOG_FILE"
    rm -f "$PID_FILE"
    return 1
  fi
}

stopDaemon() {
  if [[ ! -f "$PID_FILE" ]]; then
    echo "[daemon] Not running"
    return 0
  fi
  
  local pid
  pid=$(cat "$PID_FILE")
  
  if kill -0 "$pid" 2>/dev/null; then
    log INFO "Stopping daemon (PID $pid)..."
    kill "$pid" 2>/dev/null || true
    # Wait for graceful shutdown
    for i in {1..5}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 1
    done
    # Force kill if still alive
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
    echo "[daemon] Stopped"
    log INFO "Daemon stopped"
  else
    echo "[daemon] Was not running (stale PID file)"
  fi
  
  rm -f "$PID_FILE"
}

showStatus() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "[daemon] Running (PID $pid)"
      echo "[daemon] Log: $LOG_FILE"
      echo "[daemon] Last 5 lines:"
      tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
    else
      echo "[daemon] Not running (stale PID file)"
      rm -f "$PID_FILE"
    fi
  else
    echo "[daemon] Not running"
  fi
}

showLog() {
  local lines="${1:-20}"
  if [[ -f "$LOG_FILE" ]]; then
    echo "=== Last $lines lines of $LOG_FILE ==="
    tail -"$lines" "$LOG_FILE"
  else
    echo "[daemon] No log file found"
  fi
}

# =============================================================================
# Main
# =============================================================================

case "${1:-help}" in
  start)
    startDaemon
    ;;
  stop)
    stopDaemon
    ;;
  status)
    showStatus
    ;;
  log)
    showLog "${2:-20}"
    ;;
  run)
    runVerifiers
    ;;
  _run_inotify)
    runInotifyDaemon
    ;;
  _run_polling)
    runPollingDaemon
    ;;
  help|*)
    cat <<EOF
verifier-daemon.sh — Background file watcher for standard compliance

Usage:
  verifier-daemon.sh start         Start daemon in background
  verifier-daemon.sh stop          Stop daemon
  verifier-daemon.sh status        Show daemon status
  verifier-daemon.sh log [N]       Show last N log lines (default: 20)
  verifier-daemon.sh run           Run verifiers once (foreground)

Modes:
  inotifywait (preferred) — real-time file system events
  polling (fallback) — checks every ${POLL_INTERVAL}s

Log: $LOG_FILE
PID: $PID_FILE
EOF
    ;;
esac
