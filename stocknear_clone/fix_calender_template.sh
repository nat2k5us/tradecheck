#!/usr/bin/env bash
#
# fix_all_calendar_items.sh
#
# This script overwrites all calendar stub templates 
# (calendar_dividends.html, calendar_earnings.html, calendar_ipo.html, calendar_economic.html)
# with static content. It removes any use of `replace` or `tmpl`.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x fix_all_calendar_items.sh
#   ./fix_all_calendar_items.sh
#
# Then restart your server:
#   kill $(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this from your Django project root."
  exit 1
fi

# 2) Ensure the template directory exists
TEMPLATE_DIR="stocks/templates/stocks"
if [[ ! -d "${TEMPLATE_DIR}" ]]; then
  echo "⚠️   Directory ${TEMPLATE_DIR} does not exist; creating it."
  mkdir -p "${TEMPLATE_DIR}"
fi

# 3) Overwrite each calendar template with static content
declare -A pages=(
  [calendar_dividends.html]="Dividends"
  [calendar_earnings.html]="Earnings"
  [calendar_ipo.html]="IPO"
  [calendar_economic.html]="Economic"
)

for filename in "${!pages[@]}"; do
  title="${pages[$filename]}"
  filepath="${TEMPLATE_DIR}/${filename}"

  echo "✏️  Writing static content to ${filepath}..."
  cat > "${filepath}" << EOF
{% extends "base.html" %}
{% block title %}${title} Calendar{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-8 offset-md-2 text-center">
      <h2 class="mb-4">${title} Calendar</h2>
      <p class="text-muted">This is a stub page for the ${title} calendar.</p>
    </div>
  </div>
{% endblock %}
EOF

done

echo
echo "✅  All calendar templates have been overwritten with static content."
echo
echo "🎉  fix_all_calendar_items.sh completed."
echo "   Now restart your Django dev server:"
echo "     kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
