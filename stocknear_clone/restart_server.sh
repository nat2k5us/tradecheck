#!/usr/bin/env bash
#
# restart_server.sh
#
# This script will:
#   1. Check if any process is listening on port 8000.
#      If found, kill that process.
#   2. Invoke launch_it.sh to start a new Django dev server on port 8000.
#
# Usage:
#   chmod +x restart_server.sh
#   ./restart_server.sh
#

set -euo pipefail

PORT=8000

# 1) If something is already listening on PORT, kill its PID
if lsof -iTCP:"${PORT}" -sTCP:LISTEN -t >/dev/null 2>&1; then
  PID=$(lsof -iTCP:"${PORT}" -sTCP:LISTEN -t)
  echo "🛑  Killing existing process on port ${PORT} (PID=${PID})..."
  kill "${PID}"
  # Give it a moment to shut down
  sleep 1
else
  echo "ℹ️   No process listening on port ${PORT}."
fi

# 2) Start a fresh server via launch_site.sh
if [[ ! -f "./launch_site.sh" ]]; then
  echo "❌  Error: launch_site.sh not found in $(pwd)."
  echo "    Make sure launch_site.sh is in the same folder as this script."
  exit 1
fi

echo "🚀  Starting the server via launch_site.sh..."
# Make sure launch_site.sh is executable
chmod +x launch_site.sh
./launch_site.sh
echo "✅  Server restarted successfully."