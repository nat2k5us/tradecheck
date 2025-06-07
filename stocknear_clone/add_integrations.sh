#!/usr/bin/env bash
#
# revert_integrations.sh
#
# Revert the injection of the Integrations feature:
# 1) Remove the sidebar link in base.html
# 2) Delete the integrations/ app folder
# 3) Backup base.html before editing
#
# Usage:
#   chmod +x revert_integrations.sh
#   ./revert_integrations.sh
#

set -euo pipefail

BASE_HTML="stocknear/templates/base.html"
BACKUP_HTML="stocknear/templates/base.html.bak"

if [[ ! -f "$BASE_HTML" ]]; then
  echo "❌  Cannot find $BASE_HTML; are you in the project root?"
  exit 1
fi

echo "📦  Backing up original base.html → base.html.bak"
cp "$BASE_HTML" "$BACKUP_HTML"

echo "🗑️  Removing Integrations link from sidebar in base.html"
# On macOS, sed -i '' ... ; on Linux, sed -i ...
if sed --version >/dev/null 2>&1; then
  # GNU sed
  sed -i '/Integrations/{N;N;N;d;}' "$BASE_HTML"
else
  # BSD sed (macOS)
  sed -i '' '/Integrations/{N;N;N;d;}' "$BASE_HTML"
fi

echo "🗑️  Deleting integrations/ app directory (if present)"
rm -rf integrations

echo
echo "✅  Rolled back the Integrations feature."
echo
echo "⚠️  Next steps (manual):"
echo "   • Open settings.py and remove 'integrations' from INSTALLED_APPS."
echo "   • If you added any URLs to stocknear/urls.py for integrations, remove those lines."
echo "   • Restart your server: kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
