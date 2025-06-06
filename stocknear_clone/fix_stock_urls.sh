#!/usr/bin/env bash
#
# fix_stock_urls.sh
#
# This script rewrites stocks/urls.py so that:
#   1. 'overview/' appears before '<str:symbol>/'.
#   2. 'etf/' appears before '<str:symbol>/'.
# Running it multiple times is safe: it always writes the same content.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x fix_stock_urls.sh
#   ./fix_stock_urls.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Overwrite stocks/urls.py with correct ordering
STOCKS_URLS="stocks/urls.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_URLS} with correct URL ordering..."
cat > "${STOCKS_URLS}" << 'EOF'
from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    # List and search come first
    path('', views.stock_list, name='list'),
    path('search/', views.stock_list, name='search'),

    # Overview and ETF must come before the symbol-based detail
    path('overview/', views.stock_overview, name='overview'),
    path('etf/', views.etf_list, name='etf'),

    # Finally, detail by symbol
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
EOF

echo "✅  ${STOCKS_URLS} has been rewritten."

# 3) Remind to restart the server
echo
echo "🎉  fix_stock_urls.sh completed. Now restart your Django dev server so these URL changes take effect:"
echo "    kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t)   # kills the old runserver"
echo "    ./launch_it.sh                            # or python manage.py runserver"
