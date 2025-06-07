#!/usr/bin/env bash
#
# update_sidebar_and_calendar.sh
#
# This script renames the “List All Stocks” sidebar link to “Market movers” and adds
# a new “Calendar” dropdown with “Dividends”, “Earnings”, “IPO”, and “Economic” links.
# It also creates stub views, URL patterns, and templates for each calendar category.
#
# Safe to run multiple times: it overwrites files with the same content each run.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x update_sidebar_and_calendar.sh
#   ./update_sidebar_and_calendar.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Activate virtualenv if exists
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   No virtualenv found at ${ACTIVATE_SCRIPT}; proceeding without activation."
fi

# 3) Overwrite stocknear/templates/base.html to rename “List All Stocks” and add “Calendar” dropdown
BASE_TEMPLATE_DIR="stocknear/templates"
BASE_TEMPLATE="${BASE_TEMPLATE_DIR}/base.html"
echo "🔧  Ensuring project-level templates directory ${BASE_TEMPLATE_DIR} exists..."
mkdir -p "${BASE_TEMPLATE_DIR}"

echo "✏️  Overwriting ${BASE_TEMPLATE} to update sidebar link and add Calendar dropdown..."
cat > "${BASE_TEMPLATE}" << 'EOF'
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>{% block title %}Stocknear Clone{% endblock %}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <!-- Bootswatch Darkly theme -->
  <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootswatch@5.3.0/dist/darkly/bootstrap.min.css"
  >
  <link rel="stylesheet" href="{% static 'css/global.css' %}">
  {% block extra_head %}{% endblock %}
</head>
<body class="bg-dark text-light">
  <div class="d-flex">
    <!-- Sidebar / Control Panel -->
    <nav class="nav flex-column bg-secondary sidebar p-3">
      <h5 class="text-light mb-4">Control Panel</h5>
      <ul class="nav nav-pills flex-column">
        <li class="nav-item mb-2">
          <a class="nav-link text-light {% if request.resolver_match.url_name == 'home' %}active{% endif %}" 
             href="{% url 'home' %}">
            Home
          </a>
        </li>
        <li class="nav-item mb-2">
          <a class="nav-link text-light dropdown-toggle" data-bs-toggle="collapse" href="#stocksMenu" role="button" aria-expanded="false" aria-controls="stocksMenu">
            Stocks
          </a>
          <div class="collapse ps-3" id="stocksMenu">
            <ul class="nav flex-column">
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:list' %}">Market movers</a>
              </li>
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:overview' %}">Stocks Overview</a>
              </li>
            </ul>
          </div>
        </li>
        <li class="nav-item mb-2">
          <a class="nav-link text-light dropdown-toggle" data-bs-toggle="collapse" href="#etfMenu" role="button" aria-expanded="false" aria-controls="etfMenu">
            ETFs
          </a>
          <div class="collapse ps-3" id="etfMenu">
            <ul class="nav flex-column">
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:etf' %}">ETF List</a>
              </li>
            </ul>
          </div>
        </li>
        <li class="nav-item mb-2">
          <a class="nav-link text-light" href="{% url 'news:feed' %}">News</a>
        </li>
        <li class="nav-item mb-2">
          <a class="nav-link text-light dropdown-toggle" data-bs-toggle="collapse" href="#calendarMenu" role="button" aria-expanded="false" aria-controls="calendarMenu">
            Calendar
          </a>
          <div class="collapse ps-3" id="calendarMenu">
            <ul class="nav flex-column">
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:calendar_dividends' %}">Dividends</a>
              </li>
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:calendar_earnings' %}">Earnings</a>
              </li>
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:calendar_ipo' %}">IPO</a>
              </li>
              <li class="nav-item">
                <a class="nav-link text-light" href="{% url 'stocks:calendar_economic' %}">Economic</a>
              </li>
            </ul>
          </div>
        </li>
        <li class="nav-item mb-2">
          <a class="nav-link text-light" href="{% url 'users:dashboard' %}">Dashboard</a>
        </li>
      </ul>
    </nav>

    <!-- Main Content -->
    <div class="flex-grow-1">
      <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container-fluid">
          <a class="navbar-brand text-light" href="{% url 'home' %}">
            StocknearClone
          </a>
          <button
            class="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#mainNavbar"
          >
            <span class="navbar-toggler-icon"></span>
          </button>
          <div class="collapse navbar-collapse" id="mainNavbar">
            <ul class="navbar-nav ms-auto mb-2 mb-lg-0">
              {% if request.user.is_authenticated %}
                <li class="nav-item">
                  <a class="nav-link text-light" href="{% url 'users:logout' %}">Logout</a>
                </li>
              {% else %}
                <li class="nav-item">
                  <a class="nav-link text-light" href="{% url 'users:login' %}">Login</a>
                </li>
                <li class="nav-item">
                  <a class="nav-link text-light" href="{% url 'users:register' %}">Register</a>
                </li>
              {% endif %}
            </ul>
          </div>
        </div>
      </nav>

      <main class="container-fluid py-4">
        {% block content %}{% endblock %}
      </main>

      <footer class="bg-dark text-center text-light py-3">
        <small>© 2025 Stocknear Clone. All rights reserved.</small>
      </footer>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  {% block extra_js %}{% endblock %}
</body>
</html>
EOF

echo "✅  base.html updated with 'Market movers' link and 'Calendar' dropdown."

# 4) Overwrite stocks/views.py to add stub calendar views
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_VIEWS} to add calendar view functions..."
cat > "${STOCKS_VIEWS}" << 'EOF'
import os
import requests
from django.shortcuts import render, get_object_or_404
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
        stock_data = data[0]
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

# --- New Calendar views below ---

def calendar_dividends(request):
    """
    Stub Dividends page.
    """
    return render(request, "stocks/calendar_dividends.html")

def calendar_earnings(request):
    """
    Stub Earnings page.
    """
    return render(request, "stocks/calendar_earnings.html")

def calendar_ipo(request):
    """
    Stub IPO page.
    """
    return render(request, "stocks/calendar_ipo.html")

def calendar_economic(request):
    """
    Stub Economic calendar page.
    """
    return render(request, "stocks/calendar_economic.html")
EOF

echo "✅  stocks/views.py updated with calendar view functions."

# 5) Overwrite stocks/urls.py to add calendar URL patterns
STOCKS_URLS="stocks/urls.py"
echo "✏️  Overwriting ${STOCKS_URLS} to include calendar routes..."
cat > "${STOCKS_URLS}" << 'EOF'
from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    # Market movers and search
    path('', views.stock_list, name='list'),
    path('search/', views.stock_search, name='search'),

    # Stubs for overview and ETF
    path('overview/', views.stock_overview, name='overview'),
    path('etf/', views.etf_list, name='etf'),

    # Calendar routes
    path('calendar/dividends/', views.calendar_dividends, name='calendar_dividends'),
    path('calendar/earnings/', views.calendar_earnings, name='calendar_earnings'),
    path('calendar/ipo/', views.calendar_ipo, name='calendar_ipo'),
    path('calendar/economic/', views.calendar_economic, name='calendar_economic'),

    # Detail by symbol
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
EOF

echo "✅  stocks/urls.py updated with calendar URL patterns."

# 6) Create stub templates for each calendar category
CALENDAR_TEMPLATES=(
  "calendar_dividends.html"
  "calendar_earnings.html"
  "calendar_ipo.html"
  "calendar_economic.html"
)
for tmpl in "${CALENDAR_TEMPLATES[@]}"; do
  TEMPL_PATH="stocks/templates/stocks/${tmpl}"
  echo "🔧  Ensuring directory stocks/templates/stocks exists..."
  mkdir -p "stocks/templates/stocks"

  echo "✏️  Creating/overwriting ${TEMPL_PATH}..."
  cat > "${TEMPL_PATH}" << EOF
{% extends "base.html" %}
{% block title %}{{ tmpl|title }} Calendar{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-8 offset-md-2 text-center">
      <h2 class="mb-4">{{ tmpl|replace:"_"," "|title }} Calendar</h2>
      <p class="text-muted">This is a stub page for the {{ tmpl|replace:"_"," "|title }} calendar.</p>
    </div>
  </div>
{% endblock %}
EOF
done

echo "✅  Calendar stub templates created."

# 7) Remind to restart the server
echo
echo "🎉  update_sidebar_and_calendar.sh completed."
echo "   Restart your Django dev server so changes take effect:"
echo "     kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
echo
echo "   You can now click 'Market movers' for top gainers and 'Calendar' → 'Dividends', etc."
