#!/usr/bin/env bash
# 📜 Lontar AIEL: Automated Telemetry Exporter & Git Push (v0.1.0-alpha)
# Calculates session emission metrics using Elixir engine and pushes receipts to telemetry branch.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LONTAR_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TRANSCRIPT_DIR="${HOME}/.gemini/antigravity-cli/brain"

echo "🌿 Lontar AIEL: Starting Telemetry Sync Pipeline..."

if [ ! -d "$TRANSCRIPT_DIR" ]; then
  echo "⚠️ Warning: Transcript directory $TRANSCRIPT_DIR not found. Skipping."
  exit 0
fi

# Ensure we're in the repository
cd "$LONTAR_REPO_DIR"

# Collect unique session directories modified in the last 24 hours
MODIFIED_TRANSCRIPTS=$(find "$TRANSCRIPT_DIR" -name "transcript.jsonl" -mtime -1 2>/dev/null || true)

if [ -z "$MODIFIED_TRANSCRIPTS" ]; then
  echo "ℹ️ No session transcripts modified in the last 24 hours."
  exit 0
fi

MONTH=$(date +"%Y-%m")
TEMP_SYNC_DIR=$(mktemp -d)

# Clone or fetch the telemetry branch quietly into temporary work area
echo "📡 Checking out telemetry ledger branch..."
git clone --branch telemetry --single-branch https://github.com/zelasar-rmd/lontar-aiel.git "$TEMP_SYNC_DIR" --quiet || {
  echo "⚠️ Could not clone telemetry branch directly. Attempting local branch switch..."
  git checkout telemetry --quiet
  TEMP_SYNC_DIR="$LONTAR_REPO_DIR"
}

mkdir -p "${TEMP_SYNC_DIR}/logs"
AUDIT_COUNT=0

while IFS= read -r transcript; do
  [ -f "$transcript" ] || continue
  
  SESSION_ID=$(basename "$(dirname "$(dirname "$(dirname "$transcript")")")")
  echo "🔍 Auditing session: $SESSION_ID"
  
  # Run Elixir calculation engine with --json flag
  JSON_RECEIPT=$(elixir "${LONTAR_REPO_DIR}/scripts/calculate_emission.exs" "$transcript" --json 2>/dev/null || true)
  
  if [ -n "$JSON_RECEIPT" ]; then
    # Verify if this session receipt is already recorded in the monthly log
    LOG_FILE="${TEMP_SYNC_DIR}/logs/${MONTH}.jsonl"
    touch "$LOG_FILE"
    
    if ! grep -q "\"session_id\": \"$SESSION_ID\"" "$LOG_FILE" 2>/dev/null; then
      echo "$JSON_RECEIPT" >> "$LOG_FILE"
      echo "  ✅ Appended receipt for session $SESSION_ID"
      AUDIT_COUNT=$((AUDIT_COUNT + 1))
    else
      echo "  ℹ️ Session $SESSION_ID already recorded in $MONTH.jsonl. Skipping duplicate."
    fi
  fi
done <<< "$MODIFIED_TRANSCRIPTS"

if [ "$AUDIT_COUNT" -gt 0 ]; then
  echo "🚀 Committing $AUDIT_COUNT session receipt(s) to telemetry branch..."
  cd "$TEMP_SYNC_DIR"
  git add logs/
  git commit -m "telemetry: daily automated audit $(date +'%Y-%m-%d') [${AUDIT_COUNT} session(s)]" --quiet
  git push origin telemetry --quiet
  echo "✨ Successfully pushed $AUDIT_COUNT telemetry receipt(s) to zelasar-rmd/lontar-aiel (branch: telemetry)!"
else
  echo "ℹ️ All session receipts are up to date. No new records to commit."
fi

# Cleanup temporary worktree if used
if [ "$TEMP_SYNC_DIR" != "$LONTAR_REPO_DIR" ]; then
  rm -rf "$TEMP_SYNC_DIR"
fi

echo "🌿 Lontar AIEL: Telemetry Sync Completed."
