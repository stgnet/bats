#!/bin/bash
CERBO_HOST="192.168.1.51"
NODERED_PORT="1881"
REPO_DIR="."
FLOWS_DEST="$REPO_DIR/flows.json"

# Node-RED requires this header to accept API requests —
# without it you get the UI HTML instead of JSON
curl -sfk \
  -H "Node-RED-API-Version: v2" \
  "https://$CERBO_HOST:$NODERED_PORT/flows" \
  -o "$FLOWS_DEST"

if [ $? -ne 0 ]; then
  echo "ERROR: Could not reach Node-RED at $CERBO_HOST:$NODERED_PORT"
  exit 1
fi

cd "$REPO_DIR"

if git diff --quiet "$FLOWS_DEST"; then
  echo "No changes, skipping commit"
  exit 0
fi

#git add flows.json
#git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')"
#git push origin main
#
#echo "Backup committed and pushed"
