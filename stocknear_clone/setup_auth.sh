#!/usr/bin/env bash
#
# setup_auth.sh
#
# This script will:
#   1. Ensure it’s run from the Django project root (where manage.py lives).
#   2. Activate the virtualenv (assumes ./venv/).
#   3. Overwrite users/views.py with login/register/dashboard/password-change views,
#      including a CustomUserCreationForm so we don’t hit “Manager isn’t available” errors.
#   4. Overwrite users/urls.py with the corresponding URL patterns.
#   5. Create or overwrite the five user-related templates under users/templates/users/.
#   6. Overwrite stocknear/templates/base.html with a dark‐themed layout that includes
#      Register, Login, Dashboard, Logout, and Change Password links.
#   7. Run makemigrations and migrate to ensure the CustomUser model is in place.
#   8. Create a superuser “testadmin/Test1234!” non-interactively, if it doesn’t already exist.
#
# Running this script multiple times is safe: it overwrites files with identical content
# and checks for existing superuser before creating it.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x setup_auth.sh
#   ./setup_auth.sh
#

set -euo pipefail

# 1) Verify we’re in the directory with manage.py
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Activate the virtualenv
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ ! -f "${ACTIVATE_SCRIPT}" ]]; then
  echo "❌  Error: Virtualenv not found at ${ACTIVATE_SCRIPT}."
  echo "    Create one with: python3 -m venv venv"
  exit 1
fi

echo "🟢  Activating virtualenv..."
# shellcheck disable=SC1091
source "${ACTIVATE_SCRIPT}"

# 3) Overwrite users/views.py with login/register/dashboard/password-change logic
#    and a CustomUserCreationForm based on get_user_model()
USERS_VIEWS="users/views.py"
if [[ ! -d "users" ]]; then
  echo "❌  Error: 'users' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${USERS_VIEWS} with updated views (including CustomUserCreationForm)..."
cat > "${USERS_VIEWS}" << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout, get_user_model
from django.contrib.auth.forms import (
    AuthenticationForm,
    UserCreationForm,
    PasswordChangeForm
)
from django.contrib.auth import update_session_auth_hash
from django.contrib import messages
from django.contrib.auth.decorators import login_required

# Create a UserCreationForm that uses the swapped CustomUser model
class CustomUserCreationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = get_user_model()
        fields = ("username",)

def login_view(request):
    """
    If GET: show AuthenticationForm.
    If POST and form valid: log the user in and redirect to dashboard.
    """
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return redirect('users:dashboard')
    else:
        form = AuthenticationForm()
    return render(request, 'users/login.html', {'form': form})

def logout_view(request):
    """
    Logs the user out and redirects to home.
    """
    logout(request)
    return redirect('home')

def register_view(request):
    """
    If GET: show CustomUserCreationForm.
    If POST and form valid: create the user, log them in, redirect to dashboard.
    """
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            new_user = form.save()
            login(request, new_user)
            messages.success(
                request,
                f"Registration successful. Welcome, {new_user.username}!"
            )
            return redirect('users:dashboard')
    else:
        form = CustomUserCreationForm()
    return render(request, 'users/register.html', {'form': form})

@login_required
def dashboard_view(request):
    """
    A simple “You’re logged in as {{ user.username }}” page.
    """
    return render(request, 'users/dashboard.html')

@login_required
def change_password_view(request):
    """
    If GET: show PasswordChangeForm.
    If POST and form valid: change password, keep user logged in, redirect to confirmation.
    """
    if request.method == 'POST':
        form = PasswordChangeForm(user=request.user, data=request.POST)
        if form.is_valid():
            user = form.save()
            update_session_auth_hash(request, user)
            messages.success(request, "Your password was changed successfully.")
            return redirect('users:password_change_done')
    else:
        form = PasswordChangeForm(user=request.user)
    return render(request, 'users/change_password.html', {'form': form})

@login_required
def change_password_done_view(request):
    """
    Simple confirmation after password change.
    """
    return render(request, 'users/change_password_done.html')
EOF

# 4) Overwrite users/urls.py with new URL patterns
USERS_URLS="users/urls.py"
echo "✏️  Overwriting ${USERS_URLS} with updated URL patterns..."
cat > "${USERS_URLS}" << 'EOF'
from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('register/', views.register_view, name='register'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('change-password/', views.change_password_view, name='change_password'),
    path(
        'change-password/done/',
        views.change_password_done_view,
        name='password_change_done'
    ),
]
EOF

# 5) Create/overwrite user templates under users/templates/users/
TEMPLATE_DIR="users/templates/users"
echo "🔧  Ensuring template directory ${TEMPLATE_DIR} exists..."
mkdir -p "${TEMPLATE_DIR}"

echo "✏️  Creating/overwriting login.html..."
cat > "${TEMPLATE_DIR}/login.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Login{% endblock %}

{% block content %}
  <div class="row justify-content-center">
    <div class="col-md-4">
      <h2 class="mb-4 text-center">Login</h2>
      <form method="post" novalidate>
        {% csrf_token %}
        {{ form.non_field_errors }}
        <div class="mb-3">
          <label for="{{ form.username.id_for_label }}" class="form-label">Username</label>
          {{ form.username }}
          {% if form.username.errors %}
            <div class="text-danger">{{ form.username.errors }}</div>
          {% endif %}
        </div>
        <div class="mb-3">
          <label for="{{ form.password.id_for_label }}" class="form-label">Password</label>
          {{ form.password }}
          {% if form.password.errors %}
            <div class="text-danger">{{ form.password.errors }}</div>
          {% endif %}
        </div>
        <button type="submit" class="btn btn-primary w-100">Log In</button>
      </form>

      <div class="mt-3 text-center">
        <small>
          Don’t have an account?
          <a href="{% url 'users:register' %}">Register here</a>.
        </small>
      </div>
    </div>
  </div>
{% endblock %}
EOF

echo "✏️  Creating/overwriting register.html..."
cat > "${TEMPLATE_DIR}/register.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Register{% endblock %}

{% block content %}
  <div class="row justify-content-center">
    <div class="col-md-5">
      <h2 class="mb-4 text-center">Register</h2>
      <form method="post" novalidate>
        {% csrf_token %}
        {{ form.non_field_errors }}
        <div class="mb-3">
          <label for="{{ form.username.id_for_label }}" class="form-label">Username</label>
          {{ form.username }}
          {% if form.username.errors %}
            <div class="text-danger">{{ form.username.errors }}</div>
          {% endif %}
        </div>
        <div class="mb-3">
          <label for="{{ form.password1.id_for_label }}" class="form-label">Password</label>
          {{ form.password1 }}
          {% if form.password1.errors %}
            <div class="text-danger">{{ form.password1.errors }}</div>
          {% endif %}
        </div>
        <div class="mb-3">
          <label for="{{ form.password2.id_for_label }}" class="form-label">Confirm Password</label>
          {{ form.password2 }}
          {% if form.password2.errors %}
            <div class="text-danger">{{ form.password2.errors }}</div>
          {% endif %}
        </div>
        <button type="submit" class="btn btn-success w-100">Register</button>
      </form>

      <div class="mt-3 text-center">
        <small>
          Already have an account?
          <a href="{% url 'users:login' %}">Log in here</a>.
        </small>
      </div>
    </div>
  </div>
{% endblock %}
EOF

echo "✏️  Creating/overwriting dashboard.html..."
cat > "${TEMPLATE_DIR}/dashboard.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Dashboard{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-8 offset-md-2 text-center">
      <h2 class="mb-4">Welcome, {{ request.user.username }}!</h2>
      <p>You are successfully logged in.</p>
      <p>
        <a class="btn btn-outline-light me-2" href="{% url 'users:change_password' %}">
          Change Password
        </a>
        <a class="btn btn-danger" href="{% url 'users:logout' %}">
          Log Out
        </a>
      </p>
    </div>
  </div>
{% endblock %}
EOF

echo "✏️  Creating/overwriting change_password.html..."
cat > "${TEMPLATE_DIR}/change_password.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Change Password{% endblock %}

{% block content %}
  <div class="row justify-content-center">
    <div class="col-md-5">
      <h2 class="mb-4 text-center">Change Password</h2>
      <form method="post" novalidate>
        {% csrf_token %}
        {{ form.non_field_errors }}

        <div class="mb-3">
          <label for="{{ form.old_password.id_for_label }}" class="form-label">
            Old Password
          </label>
          {{ form.old_password }}
          {% if form.old_password.errors %}
            <div class="text-danger">{{ form.old_password.errors }}</div>
          {% endif %}
        </div>
        <div class="mb-3">
          <label for="{{ form.new_password1.id_for_label }}" class="form-label">
            New Password
          </label>
          {{ form.new_password1 }}
          {% if form.new_password1.errors %}
            <div class="text-danger">{{ form.new_password1.errors }}</div>
          {% endif %}
        </div>
        <div class="mb-3">
          <label for="{{ form.new_password2.id_for_label }}" class="form-label">
            Confirm New Password
          </label>
          {{ form.new_password2 }}
          {% if form.new_password2.errors %}
            <div class="text-danger">{{ form.new_password2.errors }}</div>
          {% endif %}
        </div>
        <button type="submit" class="btn btn-warning w-100">
          Change Password
        </button>
      </form>
    </div>
  </div>
{% endblock %}
EOF

echo "✏️  Creating/overwriting change_password_done.html..."
cat > "${TEMPLATE_DIR}/change_password_done.html" << 'EOF'
{% extends "base.html" %}
{% block title %}Password Changed{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-6 offset-md-3 text-center">
      <h2 class="mb-4">Password Successfully Changed</h2>
      <p>Your password has been updated.</p>
      <p>
        <a class="btn btn-primary" href="{% url 'users:dashboard' %}">
          Back to Dashboard
        </a>
      </p>
    </div>
  </div>
{% endblock %}
EOF

# 6) Overwrite stocknear/templates/base.html with dark theme + updated navbar
BASE_TEMPLATE_DIR="stocknear/templates"
BASE_TEMPLATE="${BASE_TEMPLATE_DIR}/base.html"
echo "🔧  Ensuring project-level templates directory ${BASE_TEMPLATE_DIR} exists..."
mkdir -p "${BASE_TEMPLATE_DIR}"

echo "✏️  Overwriting ${BASE_TEMPLATE} with updated dark-themed layout..."
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
        <ul class="navbar-nav me-auto mb-2 mb-lg-0">
          <li class="nav-item">
            <a class="nav-link text-light" href="{% url 'stocks:list' %}">Stocks</a>
          </li>
          <li class="nav-item">
            <a class="nav-link text-light" href="{% url 'news:feed' %}">News</a>
          </li>
        </ul>

        <ul class="navbar-nav mb-2 mb-lg-0">
          {% if request.user.is_authenticated %}
            <li class="nav-item">
              <a class="nav-link text-light" href="{% url 'users:dashboard' %}">
                Dashboard
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link text-light" href="{% url 'users:logout' %}">
                Logout
              </a>
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

  <main class="container py-4">
    {% block content %}{% endblock %}
  </main>

  <footer class="bg-dark text-center text-light py-3">
    <small>© 2025 Stocknear Clone. All rights reserved.</small>
  </footer>

  <script
    src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"
  ></script>
  {% block extra_js %}{% endblock %}
</body>
</html>
EOF

# 7) Run makemigrations and migrate
echo "🔨  Making migrations and migrating..."
python manage.py makemigrations
python manage.py migrate

# 8) Create the “testadmin” superuser non-interactively (if it doesn't already exist)
export DJANGO_SUPERUSER_USERNAME="testadmin"
export DJANGO_SUPERUSER_EMAIL="testadmin@example.com"
export DJANGO_SUPERUSER_PASSWORD="Test1234!"

CHECK_EXISTS=$(python manage.py shell -c "from django.contrib.auth import get_user_model; \
    User = get_user_model(); \
    print(User.objects.filter(username='testadmin').exists())")

if [[ "${CHECK_EXISTS}" == "True" ]]; then
  echo "ℹ️   Superuser 'testadmin' already exists; skipping creation."
else
  echo "🚀  Creating superuser 'testadmin'..."
  python manage.py createsuperuser --noinput
  echo "✅  Superuser 'testadmin' created with password 'Test1234!'."
fi

echo "🎉  setup_auth.sh completed. You can now:"
echo "  • Visit http://127.0.0.1:8000/users/register/ to create a new user."
echo "  • Or log in with testadmin/Test1234! at http://127.0.0.1:8000/users/login/."
echo "  • After logging in, you’ll be redirected to the Dashboard."
echo "  • Use the Change Password link on the Dashboard to update your password."
