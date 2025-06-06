#!/usr/bin/env bash
#
# use_fmp_top_movers.sh
#
# This script:
#   1. Ensures 'requests' is installed.
#   2. Overwrites stocks/views.py to fetch top 100 gainers from FinancialModelingPrep.
#   3. Overwrites stocks/templates/stocks/stock_list.html to render the movers.
#   4. Prints reminders to restart the server.
#
# Running multiple times is safe: files are simply overwritten with identical content.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x use_fmp_top_movers.sh
#   ./use_fmp_top_movers.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Activate virtualenv if it exists
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   No virtualenv found at ${ACTIVATE_SCRIPT}; continuing in system Python."
fi

# 3) Ensure 'requests' is installed
echo "🔄  Installing (or upgrading) requests..."
pip install --upgrade requests

# 4) Overwrite stocks/views.py to fetch top 100 movers from FMP
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_VIEWS} to fetch real-time Top 100 gainers from FMP..."

cat > "${STOCKS_VIEWS}" << 'EOF'
import requests
from django.shortcuts import render

def stock_list(request):
    """
    Fetch Top 100 Market Movers (gainers) from FinancialModelingPrep in real time.
    """
    # FMP endpoint for top gainers (no auth required) :contentReference[oaicite:1]{index=1}
    url = "https://financialmodelingprep.com/api/v3/stock_market/gainers"
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()  # List of dicts: symbol, name, price, changesPercentage, etc.
    except Exception as e:
        # If the call fails, fall back to an empty list and log error to console
        print(f"Error fetching FMP top gainers: {e}")
        data = []

    # Take the first 100 entries (in case FMP returns more)
    top_100 = data[:100]
    return render(request, 'stocks/stock_list.html', { 'stocks': top_100 })
EOF

# 5) Overwrite stocks/templates/stocks/stock_list.html with a movers table
TEMPLATE_DIR="stocks/templates/stocks"
TEMPLATE_FILE="${TEMPLATE_DIR}/stock_list.html"
echo "🔧  Ensuring template directory ${TEMPLATE_DIR} exists..."
mkdir -p "${TEMPLATE_DIR}"

echo "✏️  Overwriting ${TEMPLATE_FILE} to render the Top 100 movers..."

cat > "${TEMPLATE_FILE}" << 'EOF'
{% extends "base.html" %}
{% block title %}Top 100 Market Movers{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-10 offset-md-1">
      <h2 class="mb-4 text-center">Top 100 Market Movers</h2>
      <table class="table table-striped table-dark table-hover">
        <thead>
          <tr>
            <th>Rank</th>
            <th>Symbol</th>
            <th>Name</th>
            <th>Price</th>
            <th>Change %</th>
          </tr>
        </thead>
        <tbody>
          {% for s in stocks %}
            <tr>
              <td>{{ forloop.counter }}</td>
              <td>
                <a href="{% url 'stocks:detail' s.symbol %}" class="text-info">
                  {{ s.symbol }}
                </a>
              </td>
              <td>{{ s.name }}</td>
              <td>${{ s.price }}</td>
              <td
                class="{% if s.changesPercentage >= 0 %}text-success{% else %}text-danger{% endif %}"
              >
                {{ s.changesPercentage|floatformat:2 }}%
              </td>
            </tr>
          {% empty %}
            <tr>
              <td colspan="5" class="text-center">No data available.</td>
            </tr>
          {% endfor %}
        </tbody>
      </table>
    </div>
  </div>
{% endblock %}
EOF

echo "✅  use_fmp_top_movers.sh completed."
echo
echo "🎯  Now restart your Django dev server so it picks up the new view/template:"
echo "      kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t)   # kill existing runserver"
echo "      ./launch_it.sh                            # or python manage.py runserver"
echo
echo "👉 Visit http://127.0.0.1:8000/stocks/ to see real-time Top 100 gainers."
echo
echo "ℹ️  Note: This uses FinancialModelingPrep’s free endpoint, which does NOT require any API key. :contentReference[oaicite:2]{index=2}"
