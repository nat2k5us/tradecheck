#!/usr/bin/env bash
#
# fix_stock_detail_template.sh
#
# This script fixes the “Invalid filter: 'floatval'” error by updating
# stocks/templates/stocks/stock_detail.html to check the first character
# of changesPercentage (i.e. whether it starts with '-') instead of using floatval.
#
# Usage:
#   chmod +x fix_stock_detail_template.sh
#   ./fix_stock_detail_template.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Please run this from your Django project root."
  exit 1
fi

# 2) Ensure the template directory exists
TEMPLATE_DIR="stocks/templates/stocks"
DETAIL_TEMPLATE="${TEMPLATE_DIR}/stock_detail.html"

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
  echo "⚠️   Directory ${TEMPLATE_DIR} does not exist; creating it."
  mkdir -p "${TEMPLATE_DIR}"
fi

# 3) Overwrite stock_detail.html with corrected conditional
echo "✏️  Overwriting ${DETAIL_TEMPLATE} to remove use of 'floatval'..."
cat > "${DETAIL_TEMPLATE}" << 'EOF'
{% extends "base.html" %}
{% block title %}{{ stock.symbol }} Detail{% endblock %}

{% block content %}
  <div class="row justify-content-center">
    <div class="col-md-8">
      <h2 class="mb-4 text-center">
        {{ stock.symbol }} &mdash; {{ stock.name }}
      </h2>
      <table class="table table-bordered table-dark">
        <tbody>
          <tr>
            <th>Price</th>
            <td>${{ stock.price }}</td>
          </tr>
          <tr>
            <th>Change (%)</th>
            <td
              class="{% if stock.changesPercentage|slice:':1' == '-' %}text-danger{% else %}text-success{% endif %}"
            >
              {{ stock.changesPercentage|floatformat:2 }}%
            </td>
          </tr>
          <tr>
            <th>Day Low</th>
            <td>${{ stock.dayLow }}</td>
          </tr>
          <tr>
            <th>Day High</th>
            <td>${{ stock.dayHigh }}</td>
          </tr>
          <tr>
            <th>Open</th>
            <td>${{ stock.open }}</td>
          </tr>
          <tr>
            <th>Previous Close</th>
            <td>${{ stock.previousClose }}</td>
          </tr>
          <tr>
            <th>Volume</th>
            <td>{{ stock.volume }}</td>
          </tr>
          <tr>
            <th>Market Cap</th>
            <td>${{ stock.marketCap }}</td>
          </tr>
        </tbody>
      </table>
      <div class="text-center mt-4">
        <a class="btn btn-outline-light" href="{% url 'stocks:list' %}">Back to Top Movers</a>
      </div>
    </div>
  </div>
{% endblock %}
EOF

echo "✅  ${DETAIL_TEMPLATE} has been updated."
echo
echo "🎉  Now restart your Django dev server to see the fix:"
echo "    kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
