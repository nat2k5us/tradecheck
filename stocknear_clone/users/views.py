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
