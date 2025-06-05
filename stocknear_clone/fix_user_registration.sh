#!/usr/bin/env bash
#
# fix_user_registration.sh
#
# This script overwrites users/views.py so that:
#  • Registration uses CustomUser explicitly (not auth.User).
#  • The rest of the auth flows remain unchanged.
#
# Running multiple times is safe: it always writes the same correct content.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x fix_user_registration.sh
#   ./fix_user_registration.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root (where manage.py lives)
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this script from your Django project root."
  exit 1
fi

# 2) Activate virtualenv (assumes venv/ directory)
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   Warning: Virtualenv not found at ${ACTIVATE_SCRIPT}. Skipping venv activation."
fi

# 3) Overwrite users/views.py with a version that imports CustomUser directly
USERS_VIEWS="users/views.py"
if [[ ! -d "users" ]]; then
  echo "❌  Error: 'users' app folder not found."
  exit 1
fi

echo "✏️  Overwriting ${USERS_VIEWS} to use CustomUser directly…"
cat > "${USERS_VIEWS}" << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout
from django.contrib.auth.forms import AuthenticationForm, PasswordChangeForm
from django.contrib.auth import update_session_auth_hash
from django.contrib import messages
from django.contrib.auth.decorators import login_required

# Import the actual CustomUser model
from .models import CustomUser
from django import forms
from django.contrib.auth.forms import UserCreationForm

# Create a form that uses CustomUser directly
class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = CustomUser
        fields = ("username",)

    # Optionally include email if you want:
    # fields = ("username", "email")

def login_view(request):
    """
    If GET: show AuthenticationForm.
    If POST and form valid: log the user in and redirect to dashboard.
    """
    if request.method == "POST":
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return redirect("users:dashboard")
    else:
        form = AuthenticationForm()
    return render(request, "users/login.html", {"form": form})

def logout_view(request):
    """
    Logs the user out and redirects to home.
    """
    logout(request)
    return redirect("home")

def register_view(request):
    """
    If GET: show CustomUserCreationForm.
    If POST and form valid: create the user, log them in, redirect to dashboard.
    """
    if request.method == "POST":
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            new_user = form.save()
            login(request, new_user)
            messages.success(
                request,
                f"Registration successful. Welcome, {new_user.username}!"
            )
            return redirect("users:dashboard")
    else:
        form = CustomUserCreationForm()
    return render(request, "users/register.html", {"form": form})

@login_required
def dashboard_view(request):
    """
    A simple “You’re logged in as {{ user.username }}” page.
    """
    return render(request, "users/dashboard.html")

@login_required
def change_password_view(request):
    """
    If GET: show PasswordChangeForm.
    If POST and form valid: change password, keep user logged in, redirect to confirmation.
    """
    if request.method == "POST":
        form = PasswordChangeForm(user=request.user, data=request.POST)
        if form.is_valid():
            user = form.save()
            update_session_auth_hash(request, user)
            messages.success(request, "Your password was changed successfully.")
            return redirect("users:password_change_done")
    else:
        form = PasswordChangeForm(user=request.user)
    return render(request, "users/change_password.html", {"form": form})

@login_required
def change_password_done_view(request):
    """
    Simple confirmation after password change.
    """
    return render(request, "users/change_password_done.html")
EOF

echo "✅  users/views.py has been updated to use CustomUser directly."

# 4) Remind the developer to restart the server
echo
echo "🎉  Done. If your dev server is running, restart it so changes take effect:"
echo "    kill \$(lsof -iTCP:8000 -sTCP:LISTEN -t)   # kills the old runserver"
echo "    ./launch_it.sh                            # or python manage.py runserver"
