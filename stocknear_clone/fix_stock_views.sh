#!/usr/bin/env bash
#
# fix_stocks_views.sh
#
# This script restores the missing stub views (`stock_overview` and `etf_list`)
# in stocks/views.py so that the URL patterns for “overview/” and “etf/” no longer break.
# It preserves the real‐time top‐100 movers logic for `stock_list` and adds stubs
# for `stock_overview` and `etf_list`.
#
# Calling this multiple times is safe: it overwrites stocks/views.py with the same content.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x fix_stocks_views.sh
#   ./fix_stocks_views.sh
#

set -euo pipefail

# 1) Verify we're in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌ Error: manage.py not found in $(pwd)."
  echo "   Please run this script from your Django project root."
  exit 1
fi

# 2) Activate virtualenv if exists
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢 Activated virtualenv."
else
  echo "⚠️  No virtualenv found at ${ACTIVATE_SCRIPT}; proceeding without activation."
fi

# 3) Overwrite stocks/views.py with the corrected content
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌ Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Writing corrected stocks/views.py with stubs for stock_overview and etf_list..."

cat > "${STOCKS_VIEWS}" << 'EOF'
import requests
from django.shortcuts import render, get_object_or_404
from .models import Stock

def stock_list(request):
    """
    Fetch Top 100 Market Movers (gainers) in real time from FMP.
    """
    url = "https://financialmodelingprep.com/api/v3/stock_market/gainers"
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        print(f"Error fetching FMP top gainers: {e}")
        data = []

    top_100 = data[:100]
    return render(request, "stocks/stock_list.html", { "stocks": top_100 })

def stock_search(request):
    """
    Perform a basic symbol search against FMP top gainers (fallback to empty if no match).
    """
    q = request.GET.get("q", "").upper()
    results = []
    if q:
        # Fetch full gainers list again, filter by q
        url = "https://financialmodelingprep.com/api/v3/stock_market/gainers"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            all_data = resp.json()
            # Filter locally
            results = [item for item in all_data if q in item.get("symbol", "")]
        except Exception as e:
            print(f"Error fetching FMP data for search: {e}")
            results = []
    return render(request, "stocks/stock_list.html", { "stocks": results, "query": q })

def stock_detail(request, symbol):
    """
    Show details for a single stock by symbol, if present in local DB.
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

echo "✅ Updated stocks/views.py successfully."

# 4) Remind to restart the server
echo
echo "🎉 fix_stocks_views.sh completed."
echo "   If your server is running, restart it so changes take effect:"
echo "     kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
echo "   Then visit /stocks/overview/ and /stocks/etf/ to confirm they no longer 404."
