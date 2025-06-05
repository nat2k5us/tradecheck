#!/usr/bin/env bash
# init_stocknear_clone.sh
#
# This script will scaffold a “stocknear_clone” Django project on macOS,
# creating all folders, placeholder files, and a virtualenv with requirements.txt.
#
# Usage:
#   chmod +x init_stocknear_clone.sh
#   ./init_stocknear_clone.sh

set -euo pipefail

PROJECT_NAME="stocknear_clone"
DJANGO_PROJECT_DIR="stocknear"
APPS=("users" "stocks" "news")
PYTHON=python3

echo "▶️  Starting scaffold of '${PROJECT_NAME}'..."

# 1. Create project root directory
if [ -d "$PROJECT_NAME" ]; then
  echo "✋ Directory '${PROJECT_NAME}' already exists. Exiting to avoid overwrite."
  exit 1
fi
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# 2. Set up virtualenv
echo "🔧  Creating Python 3 virtual environment..."
$PYTHON -m venv venv

echo "👉  Activating venv and upgrading pip..."
# shellcheck disable=SC1091
source venv/bin/activate
pip install --upgrade pip

# 3. Install Django and common dependencies
echo "📦  Installing Django, DRF, Celery, Redis, and other libraries..."
pip install Django djangorestframework celery redis requests beautifulsoup4

# Freeze requirements.txt
pip freeze > requirements.txt

# 4. Start the Django project
echo "🚀  Creating Django project '$DJANGO_PROJECT_DIR'..."
django-admin startproject "$DJANGO_PROJECT_DIR" .

# 5. Create each app and its folder structure
for APP in "${APPS[@]}"; do
  echo "📱  Creating Django app '${APP}'..."
  python manage.py startapp "$APP"

  # Create app templates dir
  mkdir -p "$APP/templates/$APP"
  # Create app static dir
  mkdir -p "$APP/static/$APP/css"
  mkdir -p "$APP/static/$APP/js"
done

# 6. Create top-level templates and static folders
echo "🎨  Creating project-level templates and static folders..."
mkdir -p "$DJANGO_PROJECT_DIR"/templates
mkdir -p static/css static/js static/images

# 7. Create a base.html in project templates
cat > "$DJANGO_PROJECT_DIR/templates/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>{% block title %}Stocknear Clone{% endblock %}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <!-- Example: Bootstrap CSS (via CDN) -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="{% static 'css/global.css' %}">
  {% block extra_head %}{% endblock %}
</head>
<body>
  <!-- Navbar -->
  <nav class="navbar navbar-expand-lg navbar-light bg-light">
    <div class="container-fluid">
      <a class="navbar-brand" href="{% url 'home' %}">StocknearClone</a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#mainNavbar">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="mainNavbar">
        <ul class="navbar-nav me-auto mb-2 mb-lg-0">
          <li class="nav-item"><a class="nav-link" href="{% url 'stocks:list' %}">Stocks</a></li>
          <li class="nav-item"><a class="nav-link" href="{% url 'news:feed' %}">News</a></li>
          <li class="nav-item"><a class="nav-link" href="{% url 'users:login' %}">Login</a></li>
        </ul>
        <form class="d-flex" method="get" action="{% url 'stocks:search' %}">
          <input class="form-control me-2" type="search" placeholder="Search ticker..." name="q">
          <button class="btn btn-outline-success" type="submit">Search</button>
        </form>
      </div>
    </div>
  </nav>

  <main class="container my-4">
    {% block content %}
    <!-- Page-specific content will go here -->
    {% endblock %}
  </main>

  <!-- Footer -->
  <footer class="bg-light text-center py-3">
    <small>© 2025 Stocknear Clone. All rights reserved.</small>
  </footer>

  <!-- Bootstrap JS (via CDN) -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  {% block extra_js %}{% endblock %}
</body>
</html>
EOF

# 8. Create placeholder files inside each app

#######################
# 8a. USERS app
#######################
cat > "users/models.py" << 'EOF'
from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    # Extend with subscription tier, watchlist relation, etc.
    is_premium = models.BooleanField(default=False)

    def __str__(self):
        return self.username
EOF

cat > "users/admin.py" << 'EOF'
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    pass
EOF

cat > "users/urls.py" << 'EOF'
from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
]
EOF

cat > "users/views.py" << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout

def login_view(request):
    # Placeholder login view
    return render(request, 'users/login.html')

def logout_view(request):
    logout(request)
    return redirect('home')
EOF

cat > "users/serializers.py" << 'EOF'
from rest_framework import serializers
from .models import CustomUser

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'is_premium']
EOF

# Create an empty login.html template
cat > "users/templates/users/login.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Login{% endblock %}
{% block content %}
  <h2>Login</h2>
  <form method="post">
    {% csrf_token %}
    <!-- Placeholder form -->
    <div class="mb-3">
      <label for="username" class="form-label">Username</label>
      <input type="text" name="username" class="form-control" />
    </div>
    <div class="mb-3">
      <label for="password" class="form-label">Password</label>
      <input type="password" name="password" class="form-control" />
    </div>
    <button type="submit" class="btn btn-primary">Log In</button>
  </form>
{% endblock %}
EOF

#######################
# 8b. STOCKS app
#######################
cat > "stocks/models.py" << 'EOF'
from django.db import models

class Stock(models.Model):
    symbol = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=255)
    last_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    change_percent = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.symbol} - {self.name}"
EOF

cat > "stocks/admin.py" << 'EOF'
from django.contrib import admin
from .models import Stock

@admin.register(Stock)
class StockAdmin(admin.ModelAdmin):
    list_display = ('symbol', 'name', 'last_price', 'change_percent')
    search_fields = ('symbol', 'name')
EOF

cat > "stocks/urls.py" << 'EOF'
from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    path('', views.stock_list, name='list'),
    path('search/', views.stock_search, name='search'),
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
EOF

cat > "stocks/views.py" << 'EOF'
from django.shortcuts import render, get_object_or_404
from .models import Stock

def stock_list(request):
    # Placeholder: list all stocks
    stocks = Stock.objects.all()
    return render(request, 'stocks/stock_list.html', {'stocks': stocks})

def stock_search(request):
    q = request.GET.get('q', '')
    results = Stock.objects.filter(symbol__icontains=q) if q else []
    return render(request, 'stocks/stock_list.html', {'stocks': results, 'query': q})

def stock_detail(request, symbol):
    stock = get_object_or_404(Stock, symbol=symbol.upper())
    return render(request, 'stocks/stock_detail.html', {'stock': stock})
EOF

cat > "stocks/serializers.py" << 'EOF'
from rest_framework import serializers
from .models import Stock

class StockSerializer(serializers.ModelSerializer):
    class Meta:
        model = Stock
        fields = ['symbol', 'name', 'last_price', 'change_percent']
EOF

# Create stock_list.html & stock_detail.html
cat > "stocks/templates/stocks/stock_list.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Stocks{% endblock %}
{% block content %}
  <h2>Stocks {% if query %}— search results for "{{ query }}" {% endif %}</h2>
  <table class="table table-striped">
    <thead>
      <tr><th>Symbol</th><th>Name</th><th>Last Price</th><th>Change %</th></tr>
    </thead>
    <tbody>
      {% for s in stocks %}
      <tr>
        <td><a href="{% url 'stocks:detail' s.symbol %}">{{ s.symbol }}</a></td>
        <td>{{ s.name }}</td>
        <td>{{ s.last_price }}</td>
        <td>{{ s.change_percent }}%</td>
      </tr>
      {% empty %}
      <tr><td colspan="4">No stocks to display.</td></tr>
      {% endfor %}
    </tbody>
  </table>
{% endblock %}
EOF

cat > "stocks/templates/stocks/stock_detail.html" << 'EOF'
{% extends "base.html" %}
{% block title %}{{ stock.symbol }}{% endblock %}
{% block content %}
  <h2>{{ stock.symbol }} — {{ stock.name }}</h2>
  <p>Last Price: ${{ stock.last_price }} (<span class="text-success">{{ stock.change_percent }}%</span>)</p>
  <!-- Placeholder for charts, order flow, etc. -->
  <div id="price-chart-container">
    <!-- Later: embed Chart.js graph here -->
  </div>
{% endblock %}
EOF

#######################
# 8c. NEWS app
#######################
cat > "news/models.py" << 'EOF'
from django.db import models

class NewsItem(models.Model):
    headline = models.CharField(max_length=500)
    url = models.URLField()
    timestamp = models.DateTimeField()

    def __str__(self):
        return self.headline
EOF

cat > "news/admin.py" << 'EOF'
from django.contrib import admin
from .models import NewsItem

@admin.register(NewsItem)
class NewsItemAdmin(admin.ModelAdmin):
    list_display = ('headline', 'timestamp')
    ordering = ('-timestamp',)
EOF

cat > "news/urls.py" << 'EOF'
from django.urls import path
from . import views

app_name = 'news'

urlpatterns = [
    path('', views.news_feed, name='feed'),
]
EOF

cat > "news/views.py" << 'EOF'
from django.shortcuts import render
from .models import NewsItem

def news_feed(request):
    # Placeholder: show most recent news items
    items = NewsItem.objects.order_by('-timestamp')[:50]
    return render(request, 'news/news_feed.html', {'items': items})
EOF

cat > "news/serializers.py" << 'EOF'
from rest_framework import serializers
from .models import NewsItem

class NewsSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsItem
        fields = ['headline', 'url', 'timestamp']
EOF

cat > "news/templates/news/news_feed.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Market News{% endblock %}
{% block content %}
  <h2>Market News</h2>
  <ul class="list-group">
    {% for n in items %}
    <li class="list-group-item">
      <small class="text-muted">{{ n.timestamp|date:"M d, Y H:i" }}</small><br>
      <a href="{{ n.url }}" target="_blank">{{ n.headline }}</a>
    </li>
    {% empty %}
    <li class="list-group-item">No news available.</li>
    {% endfor %}
  </ul>
{% endblock %}
EOF

# 9. Create a simple home view & URL in project urls.py
PROJECT_URLS="$DJANGO_PROJECT_DIR/urls.py"
cat > "$PROJECT_URLS" << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import render

def home(request):
    return render(request, 'base.html')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('users/', include('users.urls', namespace='users')),
    path('stocks/', include('stocks.urls', namespace='stocks')),
    path('news/', include('news.urls', namespace='news')),
]
EOF

# 10. Update settings.py: register apps, templates, static files
SETTINGS_FILE="$DJANGO_PROJECT_DIR/settings.py"

# Insert at top of settings.py: import os
sed -i '' '1s/^/import os\n/' "$SETTINGS_FILE"

# Append to INSTALLED_APPS
# (Careful: this uses macOS sed syntax; backup is created automatically by -i '')
sed -i '' "/INSTALLED_APPS = \[/ a\\
    'rest_framework',\\
    'users',\\
    'stocks',\\
    'news',\
" "$SETTINGS_FILE"

# Configure TEMPLATES DIR and STATIC settings
sed -i '' "/'DIRS': \[/ a\\
                os.path.join(BASE_DIR, '$DJANGO_PROJECT_DIR/templates'),\
" "$SETTINGS_FILE"

# Add STATIC_URL and STATICFILES_DIRS at bottom
cat >> "$SETTINGS_FILE" << 'EOF'

# ----- Static & Media settings -----
STATIC_URL = '/static/'
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]
EOF

# 11. Create .gitignore
cat > .gitignore << 'EOF'
# Python & Django
*.pyc
__pycache__/
db.sqlite3
.env
venv/
*.log

# macOS system files
.DS_Store

# VSCode / IDE config
.vscode/
.idea/
EOF

# 12. Create a stub README.md
cat > README.md << 'EOF'
# Stocknear Clone

This is a Django-based scaffold to clone the basic functionality of Stocknear.com:
- Real-time (or near real-time) stock quotes, top movers lists.
- Market news feed.
- User authentication (with free vs. premium tiers).
- Demo templates using Bootstrap 5.

## How to run locally

1. **Activate virtualenv**  
   \`\`\`bash
   source venv/bin/activate
   \`\`\`
2. **Apply migrations & create superuser**  
   \`\`\`bash
   python manage.py migrate
   python manage.py createsuperuser
   \`\`\`
3. **Run the development server**  
   \`\`\`bash
   python manage.py runserver
   \`\`\`
4. Visit [http://localhost:8000/](http://localhost:8000/) to see the home page.

## Next Steps

- Wire up actual data-fetch tasks (e.g., Celery beat + Celery worker) to populate \`Stock\` and \`NewsItem\`.  
- Build out DRF endpoints for JSON-powered widgets (e.g., top gainers, flow feed).  
- Flesh out front-end templates & JavaScript (Chart.js) for price charts and interactive tables.

EOF

# 13. Final message
echo "✅  Scaffold complete! Navigate into '${PROJECT_NAME}', activate venv, then 'python manage.py migrate' and start building."
