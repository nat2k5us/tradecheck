#!/usr/bin/env bash
#
# clean_migrations.sh
#
# This script:
#   1. Checks that it’s run from the Django project root (where manage.py lives).
#   2. Verifies that the 'sqlite3' CLI is installed.
#   3. Verifies that Python can 'import sqlite3' (i.e., the sqlite3 module is available).
#   4. Removes all existing migrations for each app and the project itself.
#   5. Deletes the SQLite database file (db.sqlite3) if it exists.
#   6. Re-generates migrations and applies them.
#
# Usage:
#   cd <dir-containing-manage.py> && ./clean_migrations.sh
#

set -euo pipefail

# -------------------------------
# 1) Ensure we’re running from the folder that contains manage.py
# -------------------------------
ROOT_DIR="$(pwd)"
if [[ ! -f "${ROOT_DIR}/manage.py" ]]; then
  echo "❌  Error: manage.py not found in the current directory (${ROOT_DIR})."
  echo "    Please run this script from the Django project root (where manage.py lives)."
  exit 1
fi

echo "✅  Found manage.py in ${ROOT_DIR}. Continuing..."

# -------------------------------
# 2) Check that the 'sqlite3' CLI is installed
# -------------------------------
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "❌  Error: The 'sqlite3' command-line utility is not installed or not in your PATH."
  echo "    Django uses sqlite3 by default, so you need to install it."
  echo "    On macOS, you can install via Homebrew:"
  echo "      brew install sqlite3"
  exit 1
fi

echo "✅  'sqlite3' CLI found."

# -------------------------------
# 3) Check that Python can 'import sqlite3'
# -------------------------------
# (This verifies that your Python build has the SQLite extension enabled.)
if ! python - << 'EOF' &>/dev/null
import sqlite3
EOF
then
  echo "❌  Error: The current Python interpreter does not have the 'sqlite3' module available."
  echo "    When Python is built without SQLite support, Django cannot use sqlite3 as a database."
  echo "    You’ll need a Python build that includes sqlite3 (on macOS, the system Python should have it)."
  exit 1
fi

echo "✅  Python has the 'sqlite3' module."

# -------------------------------
# 4) Define app names and project folder name
# -------------------------------
APPS=(users stocks news)
PROJECT_APP="stocknear"

# -------------------------------
# 5) Remove each app’s migrations folder (if it exists), then recreate a fresh one
# -------------------------------
for APP in "${APPS[@]}"; do
  MIG_DIR="${APP}/migrations"
  if [[ -d "${MIG_DIR}" ]]; then
    echo "🗑️  Removing existing migrations directory: ${MIG_DIR}"
    rm -rf "${MIG_DIR}"
  else
    echo "ℹ️   No migrations directory for '${APP}' (skipping removal)."
  fi

  echo "🆕  Recreating migrations folder for '${APP}'"
  mkdir -p "${MIG_DIR}"
  touch "${MIG_DIR}/__init__.py"
done

# -------------------------------
# 6) Remove project-level migrations (if any), then recreate
# -------------------------------
PROJ_MIG_DIR="${PROJECT_APP}/migrations"
if [[ -d "${PROJ_MIG_DIR}" ]]; then
  echo "🗑️  Removing existing project-level migrations: ${PROJ_MIG_DIR}"
  rm -rf "${PROJ_MIG_DIR}"
else
  echo "ℹ️   No project-level migrations directory (${PROJ_MIG_DIR}), skipping."
fi

echo "🆕  Recreating project-level migrations folder"
mkdir -p "${PROJ_MIG_DIR}"
touch "${PROJ_MIG_DIR}/__init__.py"

# -------------------------------
# 7) Delete the SQLite database file (if it exists)
# -------------------------------
DB_FILE="db.sqlite3"
if [[ -f "${DB_FILE}" ]]; then
  echo "🗑️  Deleting existing database file: ${DB_FILE}"
  rm -f "${DB_FILE}"
else
  echo "ℹ️   No SQLite database file (${DB_FILE}), skipping deletion."
fi

# -------------------------------
# 8) (Optional) Check for activated virtualenv
# -------------------------------
# Uncomment the block below if you want to enforce that a virtualenv is active.
# However, if you rely on the system or another Python, you may skip this.
#
if [[ -z "${VIRTUAL_ENV:-}" ]]; then
  echo "⚠️   Warning: No virtual environment detected."
  echo "    It’s recommended to activate your project’s venv before running migrations."
  # exit 1
else
  echo "✅  Virtualenv is active: ${VIRTUAL_ENV}"
fi

# -------------------------------
# 9) Regenerate migrations
# -------------------------------
echo "🚀  Running 'python manage.py makemigrations' for all apps..."
python manage.py makemigrations

# -------------------------------
# 10) Apply migrations
# -------------------------------
echo "🚀  Running 'python manage.py migrate'..."
python manage.py migrate

echo "🎉  Clean migrations complete. Database and migrations have been reset."
