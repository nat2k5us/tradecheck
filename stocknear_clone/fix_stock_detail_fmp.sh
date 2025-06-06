#!/usr/bin/env bash
#
# fix_stock_detail_fmp.sh
#
# This script updates the stock detail view so that clicking a symbol fetches real-time data
# from FinancialModelingPrep (using FMP_API_KEY) instead of looking in the local DB. It:
#
#   1. Verifies you’re in the Django project root.
#   2. Ensures FMP_API_KEY is set in the environment.
#   3. Overwrites stocks/views.py: replaces get_object_or_404 against local Stock with a call
#      to FMP’s `/quote/{symbol}` endpoint.  
#   4. Creates stocks/templates/stocks/stock_detail.html to render the fetched data.
#   5. Leaves stocks/urls.py unchanged (it already routes `<str:symbol>/` to stock_detail).
#
# Safe to run multiple times: it always writes the same content.
#
# Usage:
#   export FMP_API_KEY="your_api_key_here"
#   chmod +x fix_stock_detail_fmp.sh
#   ./fix_stock_detail_fmp.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Please run this script from your Django project root."
  exit 1
fi

# 2) Ensure FMP_API_KEY is set
if [[ -z "${FMP_API_KEY:-}" ]]; then
  echo "❌  Error: FMP_API_KEY environment variable is not set."
  echo "    export FMP_API_KEY=\"your_api_key_here\""
  exit 1
fi

# 3) Activate virtualenv if exists
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   No virtualenv found at ${ACTIVATE_SCRIPT}; proceeding with system Python."
fi

# 4) Overwrite stocks/views.py to fetch detail from FMP
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_VIEWS} so stock_detail pulls from FMP instead of local DB..."
cat > "${STOCKS_VIEWS}" << 'EOF'
import os
import requests
from django.shortcuts import render, redirect
from django.http import Http404
from .models import Stock

FMP_API_KEY = os.environ.get("FMP_API_KEY", "")

def stock_list(request):
    """
    Fetch Top 100 Market Movers (gainers) from FMP using your API key.
    """
    if not FMP_API_KEY:
        print("Error: FMP_API_KEY not set.")
        movers = []
    else:
        url = f"https://financialmodelingprep.com/api/v3/stock_market/gainers?apikey={FMP_API_KEY}"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            data = resp.json()
        except Exception as e:
            print(f"Error fetching FMP top gainers: {e}")
            data = []
        movers = data[:100]
    return render(request, "stocks/stock_list.html", { "stocks": movers })

def stock_search(request):
    """
    Filter the FMP gainers list by a case-insensitive substring match on symbol.
    """
    q = request.GET.get("q", "").upper()
    results = []
    if q and FMP_API_KEY:
        url = f"https://financialmodelingprep.com/api/v3/stock_market/gainers?apikey={FMP_API_KEY}"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            all_data = resp.json()
            results = [item for item in all_data if q in item.get("symbol", "")]
        except Exception as e:
            print(f"Error fetching FMP data for search: {e}")
            results = []
    return render(request, "stocks/stock_list.html", { "stocks": results, "query": q })

def stock_detail(request, symbol):
    """
    Fetch real-time stock detail from FMP using `/quote/{symbol}` endpoint.
    """
    symbol = symbol.upper()
    if not FMP_API_KEY:
        raise Http404("API key not configured.")

    url = f"https://financialmodelingprep.com/api/v3/quote/{symbol}?apikey={FMP_API_KEY}"
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if not data:
            raise Http404(f"No data for symbol {symbol}")
        stock_data = data[0]  # first (and only) element
    except Http404:
        raise
    except Exception as e:
        print(f"Error fetching FMP detail for {symbol}: {e}")
        raise Http404(f"Could not retrieve data for {symbol}")

    return render(request, "stocks/stock_detail.html", { "stock": stock_data })

def stock_overview(request):
    """
    Stub Stocks Overview page.
    """
    return render(request, "stocks/stock_overview.html")

def etf_list(request):
    """
    Stub ETF List page.
    """
    return render(request, "stocks/etf_list.html")
EOF

# 5) Create/overwrite stocks/templates/stocks/stock_detail.html
TEMPLATE_DIR="stocks/templates/stocks"
DETAIL_TEMPLATE="${TEMPLATE_DIR}/stock_detail.html"
echo "🔧  Ensuring directory ${TEMPLATE_DIR} exists..."
mkdir -p "${TEMPLATE_DIR}"

echo "✏️  Creating/overwriting ${DETAIL_TEMPLATE}..."
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
              class="{% if stock.changesPercentage|floatformat:2|floatval >= 0 %}text-success{% else %}text-danger{% endif %}"
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

echo "✅  Created stock_detail.html to display real-time data from FMP."

echo
echo "🎉  fix_stock_detail_fmp.sh completed."
echo "   Restart your Django dev server so it picks up these changes:"
echo "     kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
echo
echo "   After restarting, clicking a symbol will fetch live details from FMP."
