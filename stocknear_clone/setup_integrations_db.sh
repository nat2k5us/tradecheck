#!/usr/bin/env bash
#
# setup_integrations_db.sh
#
# Creates and applies migrations for the 'integrations' app so its database table exists.
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x setup_integrations_db.sh
#   ./setup_integrations_db.sh
#
set -euo pipefail

# 1) Verify Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  manage.py not found. Run this script from the Django project root."
  exit 1
fi

# 2) Activate virtualenv if present
if [[ -f "venv/bin/activate" ]]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🟢  Activated virtualenv."
fi

# 3) Make migrations for integrations
echo "🔨  Running makemigrations for 'integrations'..."
python manage.py makemigrations integrations

# 4) Apply migrations
echo "🚀  Applying migrations..."
python manage.py migrate integrations

# 5) Confirm table created
echo "✅  Migrations applied. 'integrations_integration' table should now exist."

echo "🎉  Done. You can now runserver and visit /integrations/ without OperationalError."
