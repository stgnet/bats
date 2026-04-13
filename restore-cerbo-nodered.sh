#!/bin/bash
CERBO_HOST="192.168.1.51"
NODERED_PORT="1881"
FLOWS_FILE="${1:-./flows.json}"   # takes optional path arg, defaults to ./flows.json

if [ ! -f "$FLOWS_FILE" ]; then
  echo "ERROR: Flows file not found: $FLOWS_FILE"
  exit 1
fi

echo "Pushing $FLOWS_FILE to Node-RED at $CERBO_HOST:$NODERED_PORT..."

HTTP_CODE=$(curl -sk \
  -X POST \
  -H "Node-RED-API-Version: v2" \
  -H "Content-Type: application/json" \
  -w "%{http_code}" \
  -o /dev/null \
  "https://$CERBO_HOST:$NODERED_PORT/flows" \
  -d "@$FLOWS_FILE")

# 200 = deployed, 204 = no content (also success)
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
  echo "Success — flows deployed (HTTP $HTTP_CODE)"
else
  echo "ERROR: Unexpected response HTTP $HTTP_CODE"
  exit 1
fi
