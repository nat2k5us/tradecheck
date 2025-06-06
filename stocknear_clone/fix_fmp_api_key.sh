#!/usr/bin/env bash
#
# fix_fmp_api_key.sh
#
# This script rewrites stocks/views.py so that the gainers URL includes your FMP API key
# read from the environment variable FMP_API_KEY. Running it multiple times is safe—it
# always writes the same content.
#
# Usage:
#   export FMP_API_KEY="your_actual_key_here"
#   chmod +x fix_fmp_api_key.sh
#   ./fix_fmp_api_key.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this from your Django project root."
  exit 1
fi

# 2) Ensure FMP_API_KEY is set
if [[ -z "${FMP_API_KEY:-}" ]]; then
  echo "❌  Error: FMP_API_KEY environment variable is not set."
  echo "    export FMP_API_KEY=\"your_api_key_here\""
  exit 1
fi

# 3) Activate virtualenv if it exists
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   No virtualenv found at ${ACTIVATE_SCRIPT}; proceeding without venv."
fi

# 4) Overwrite stocks/views.py
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_VIEWS} to include FMP_API_KEY..."
cat > "${STOCKS_VIEWS}" << 'EOF'
import os
import requests
from django.shortcuts import render, get_object_or_404
from .models import Stock

def stock_list(request):
    """
    Fetch Top 100 Market Movers (gainers) from FMP using your API key.
    """
    api_key = os.environ.get("FMP_API_KEY")
    if not api_key:
        # If the key is missing at runtime, show an empty list and log
        print("Error: FMP_API_KEY not set.")
        top_100 = []
    else:
        url = f"https://financialmodelingprep.com/api/v3/stock_market/gainers?apikey={api_key}"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            data = resp.json()
        except Exception as e:
            print(f"Error fetching FMP top gainers: {e}")
            data = []

        top_100 = data[:100]  # take first 100 if available

    return render(request, "stocks/stock_list.html", { "stocks": top_100 })

def stock_search(request):
    """
    Filter the FMP gainers list by a case-insensitive substring match on symbol.
    """
    q = request.GET.get("q", "").upper()
    results = []
    api_key = os.environ.get("FMP_API_KEY")
    if q and api_key:
        url = f"https://financialmodelingprep.com/api/v3/stock_market/gainers?apikey={api_key}"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            all_data = resp.json()
            # Filter locally for symbols containing 'q'
            results = [item for item in all_data if q in item.get("symbol", "")]
        except Exception as e:
            print(f"Error fetching FMP data for search: {e}")
            results = []
    return render(request, "stocks/stock_list.html", { "stocks": results, "query": q })

def stock_detail(request, symbol):
    """
    Show details for a single stock by symbol if present in local DB.
    """
    stock = get_object_or_404(Stock, symbol=symbol.upper())
    return render(request, "stocks/stock_detail.html", { "stock": stock })

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

echo "✅  stocks/views.py has been updated to include FMP_API_KEY."
echo
echo "🎉  Now restart your Django dev server:"
echo "      kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
echo
echo "💡  Ensure FMP_API_KEY remains in your environment whenever you run the server."
