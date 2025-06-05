#!/usr/bin/env bash
#
# add_sidebar.sh
#
# This script adds a left-hand Control Panel (sidebar) to the existing Django project 
# and creates a new “ETF List” page under the stocks app. It updates:
#   1. stocknear/templates/base.html      → injects a sidebar with navigation links
#   2. stocks/views.py                   → adds an etf_list view
#   3. stocks/urls.py                    → adds a URL route for the ETF page
#   4. stocks/templates/stocks/etf_list.html → creates a stub template for the ETF page
#   5. static/css/global.css             → adds some basic styling for the sidebar
#
# The script is idempotent: running it multiple times simply overwrites the same content,
# preserving navigation to Home, Stocks, ETF, etc. without breaking existing code.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x add_sidebar.sh
#   ./add_sidebar.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root (where manage.py lives)
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Activate the virtualenv (optional)
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   Warning: Virtualenv not found at ${ACTIVATE_SCRIPT}. Continuing without venv."
fi

# 3) Overwrite stocknear/templates/base.html to include a sidebar
BASE_TEMPLATE_DIR="stocknear/templates"
BASE_TEMPLATE="${BASE_TEMPLATE_DIR}/base.html"

echo "🔧  Ensuring project-level templates directory ${BASE_TEMPLATE_DIR} exists..."
mkdir -p "${BASE_TEMPLATE_DIR}"

echo "✏️  Overwriting ${BASE_TEMPLATE} to add a left-hand sidebar..."
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
                <a class="nav-link text-light" href="{% url 'stocks:list' %}">List All Stocks</a>
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

# 4) Overwrite stocks/views.py to add etf_list and stocks_overview views
STOCKS_VIEWS="stocks/views.py"
if [[ ! -d "stocks" ]]; then
  echo "❌  Error: 'stocks' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${STOCKS_VIEWS} to add ETF and Stocks Overview views..."
cat > "${STOCKS_VIEWS}" << 'EOF'
from django.shortcuts import render, get_object_or_404
from .models import Stock

def stock_list(request):
    """
    List all stocks or search results.
    """
    q = request.GET.get('q', '')
    if q:
        results = Stock.objects.filter(symbol__icontains=q.upper())
    else:
        results = Stock.objects.all()
    return render(request, 'stocks/stock_list.html', {'stocks': results, 'query': q})

def stock_detail(request, symbol):
    """
    Show details for a single stock.
    """
    stock = get_object_or_404(Stock, symbol=symbol.upper())
    return render(request, 'stocks/stock_detail.html', {'stock': stock})

def stock_overview(request):
    """
    A stub Stocks Overview page.
    """
    # You can populate context with summary data in the future
    return render(request, 'stocks/stock_overview.html')

def etf_list(request):
    """
    A stub ETF List page.
    """
    # Replace with actual ETF data retrieval later
    context = { 'etfs': [] }
    return render(request, 'stocks/etf_list.html', context)
EOF

# 5) Overwrite stocks/urls.py to include routes for stock_overview and etf_list
STOCKS_URLS="stocks/urls.py"
echo "✏️  Overwriting ${STOCKS_URLS} to add new URL patterns..."
cat > "${STOCKS_URLS}" << 'EOF'
from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    path('', views.stock_list, name='list'),
    path('search/', views.stock_list, name='search'),
    path('<str:symbol>/', views.stock_detail, name='detail'),
    path('overview/', views.stock_overview, name='overview'),
    path('etf/', views.etf_list, name='etf'),
]
EOF

# 6) Create stocks/templates/stocks/etf_list.html (stub page)
ETFS_TEMPLATE_DIR="stocks/templates/stocks"
ETFS_TEMPLATE="${ETFS_TEMPLATE_DIR}/etf_list.html"

echo "🔧  Ensuring template directory ${ETFS_TEMPLATE_DIR} exists..."
mkdir -p "${ETFS_TEMPLATE_DIR}"

echo "✏️  Creating/overwriting ${ETFS_TEMPLATE}..."
cat > "${ETFS_TEMPLATE}" << 'EOF'
{% extends "base.html" %}
{% block title %}ETF List{% endblock %}

{% block content %}
  <h2 class="text-center mb-4">ETF List</h2>
  <p class="text-center text-muted">No ETFs available yet. (Stub page)</p>
{% endblock %}
EOF

# 7) Create stocks/templates/stocks/stock_overview.html (stub page)
OVERVIEW_TEMPLATE="${ETFS_TEMPLATE_DIR}/stock_overview.html"
echo "✏️  Creating/overwriting ${OVERVIEW_TEMPLATE}..."
cat > "${OVERVIEW_TEMPLATE}" << 'EOF'
{% extends "base.html" %}
{% block title %}Stocks Overview{% endblock %}

{% block content %}
  <h2 class="text-center mb-4">Stocks Overview</h2>
  <p class="text-center text-muted">Summary data will appear here. (Stub page)</p>
{% endblock %}
EOF

# 8) Update static/css/global.css with sidebar styling (if not already present)
GLOBAL_CSS="static/css/global.css"
echo "🔧  Ensuring static/css directory exists..."
mkdir -p static/css

echo "🔄  Appending sidebar-specific styles to ${GLOBAL_CSS}..."
grep -q "/* Sidebar styling */" "${GLOBAL_CSS}" 2>/dev/null || cat >> "${GLOBAL_CSS}" << 'EOF'

/* Sidebar styling */
.sidebar {
  width: 240px;
  min-height: 100vh;
}
.sidebar .nav-link {
  color: #e0e0e0;
}
.sidebar .nav-link.active {
  background-color: #343a40;
}
EOF

# 9) Remind developer to update project's urlpatterns if needed
echo
echo "🎉  add_sidebar.sh completed. Please ensure your root urls.py includes the updated stocks URLs."
echo "For example, in stocknear/urls.py, confirm you have:"
echo "    path('stocks/', include('stocks.urls', namespace='stocks'))"
echo
echo "Then restart your server: kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t) && ./launch_it.sh"
echo "Done! Your sidebar and ETF List page are now set up."