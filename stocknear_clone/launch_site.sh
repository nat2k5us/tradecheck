#!/usr/bin/env bash
#
# launch_site.sh
#
# Usage:
#   chmod +x launch_site.sh
#   ./launch_site.sh
#
# This script:
#   1. Ensures manage.py exists in the current directory.
#   2. Checks if port 8000 is already in use. If so, it exits with an error.
#   3. Activates the Python virtualenv (assumed at ./venv/).
#   4. Launches "python manage.py runserver" in the background, logging to runserver.log.
#   5. Waits briefly, then opens http://127.0.0.1:8000/ in your default macOS browser.
#

set -euo pipefail

# 1) Ensure we’re in the directory with manage.py
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Please run this script from your Django project root (where manage.py lives)."
  exit 1
fi

# 2) Check if port 8000 is in use
PORT=8000
if lsof -iTCP:"${PORT}" -sTCP:LISTEN -t >/dev/null 2>&1; then
  PID_IN_USE=$(lsof -iTCP:"${PORT}" -sTCP:LISTEN -t)
  echo "❌  Error: Port ${PORT} is already in use by process PID ${PID_IN_USE}."
  echo "    Please stop that process or choose a different port."
  exit 1
fi
echo "✅  Port ${PORT} is free."

# 3) Activate the venv
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"

if [[ ! -f "${ACTIVATE_SCRIPT}" ]]; then
  echo "❌  Error: Virtualenv not found at ${ACTIVATE_SCRIPT}."
  echo "    Make sure you have a Python virtualenv in ./venv/."
  echo "    You can create one with: python3 -m venv venv"
  exit 1
fi

echo "🟢  Activating virtualenv (${ACTIVATE_SCRIPT})..."
# shellcheck disable=SC1091
source "${ACTIVATE_SCRIPT}"

# 4) Run the Django development server in the background
LOGFILE="runserver.log"
echo "🚀  Launching Django development server on port ${PORT} (logs → ${LOGFILE})..."
python manage.py runserver 127.0.0.1:"${PORT}" >"${LOGFILE}" 2>&1 &

# Capture the PID so you can stop it later if needed
RUNSERVER_PID=$!
echo "    → runserver PID: ${RUNSERVER_PID}"

# 5) Give the server a moment to start
sleep 1

# 6) Open the browser to the homepage
URL="http://127.0.0.1:${PORT}/"
echo "🌐  Opening browser to ${URL}..."
open "${URL}"

echo "✅  Done. Django is running in the background (PID=${RUNSERVER_PID}),"
echo "    logs are being written to ${LOGFILE}."
echo "    To stop the server, run: kill ${RUNSERVER_PID}"
