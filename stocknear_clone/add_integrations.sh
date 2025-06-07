#!/usr/bin/env bash
#
# add_integrations.sh
#
# This script scaffolds an "integrations" feature in your Django project:
#   - Creates an 'integrations' app (if missing)
#   - Adds an Integration model to store provider, username, keychain key, and verified status
#   - Uses python-keyring (or MacOSKeychainManager) to securely store passwords/API keys in the OS keychain
#   - Adds views, forms, URLs, and templates for listing, creating/updating, and verifying integrations
#   - Injects a new "Integrations" link in the sidebar (at bottom of control panel)
#
# After running, you must:
#   1. pip install django-keyring python-keyring
#   2. python manage.py makemigrations integrations
#   3. python manage.py migrate
#   4. restart your server
#
set -euo pipefail

# 1) Verify we’re in the Django project root
if [[ ! -f "./manage.py" ]]; then
  echo "❌ Error: managed.py not found. Run this in the project root."
  exit 1
fi

# 2) Activate virtualenv if exists
if [[ -f "venv/bin/activate" ]]; then
  source venv/bin/activate
  echo "🟢 Activated virtualenv."
else
  echo "⚠️  No virtualenv found; proceeding with system Python."
fi

# 3) Ensure django-keyring and keyring are in requirements
REQ=requirements.txt
if ! grep -q "django-keyring" $REQ; then echo "django-keyring>=1.4.0" >> $REQ; fi
if ! grep -q "keyring" $REQ; then echo "keyring>=23.0.1" >> $REQ; fi
pip install django-keyring keyring

# 4) Create integrations app if needed
if [[ ! -d "integrations" ]]; then
  echo "📦 Creating integrations app..."
  python manage.py startapp integrations
fi

# 5) Write integrations/models.py
cat > integrations/models.py << 'EOF'
from django.db import models
from django.contrib.auth import get_user_model

PROVIDER_CHOICES = [
    ('webull', 'Webull'),
    ('robinhood', 'Robinhood'),
    ('fidelity', 'Fidelity'),
]

User = get_user_model()

class Integration(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    provider = models.CharField(max_length=32, choices=PROVIDER_CHOICES)
    username = models.CharField(max_length=255)
    key_name = models.CharField(max_length=255, help_text="Keyring item name")  # used by keyring
    verified = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'provider')

    def __str__(self):
        return f"{self.user} – {self.provider}"
EOF

echo "✅ integrations/models.py written."

# 6) Write integrations/forms.py
cat > integrations/forms.py << 'EOF'
import keyring
from django import forms
from .models import Integration

class IntegrationForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(render_value=True),
        required=True,
        help_text="API key or password"
    )

    class Meta:
        model = Integration
        fields = ['provider', 'username']

    def __init__(self, *args, **kwargs):
        # Pop initial password from keychain if existing
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            pw = keyring.get_password(self.instance.provider, self.instance.username)
            self.fields['password'].initial = pw

    def save(self, commit=True):
        inst = super().save(commit=False)
        # generate key_name as provider:username
        key_name = f"{inst.provider}:{inst.username}"
        inst.key_name = key_name
        if commit:
            inst.save()
            keyring.set_password(inst.provider, inst.username, self.cleaned_data['password'])
        return inst
EOF

echo "✅ integrations/forms.py written."

# 7) Write integrations/views.py
cat > integrations/views.py << 'EOF'
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Integration
from .forms import IntegrationForm
import keyring
from stocks.views import stock_detail  # reuse quote fetch

@login_required
def integration_list(request):
    items = Integration.objects.filter(user=request.user)
    return render(request, 'integrations/list.html', {'items': items})

@login_required
def integration_edit(request, pk=None):
    if pk:
        inst = get_object_or_404(Integration, pk=pk, user=request.user)
    else:
        inst = Integration(user=request.user)
    if request.method == 'POST':
        form = IntegrationForm(request.POST, instance=inst)
        if form.is_valid():
            form.save()
            return redirect('integrations:list')
    else:
        form = IntegrationForm(instance=inst)
    return render(request, 'integrations/form.html', {'form': form})

@login_required
def integration_verify(request, pk):
    inst = get_object_or_404(Integration, pk=pk, user=request.user)
    # attempt a quote fetch for AAPL via WebullManager or Robinhood logic
    try:
        # simplistic: call stock_detail view to get context
        resp = stock_detail(request, 'AAPL')
        inst.verified = True
    except Exception:
        inst.verified = False
    inst.save()
    return redirect('integrations:list')
EOF

echo "✅ integrations/views.py written."

# 8) Write integrations/urls.py
cat > integrations/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'integrations'
urlpatterns = [
    path('', views.integration_list, name='list'),
    path('add/', views.integration_edit, name='add'),
    path('edit/<int:pk>/', views.integration_edit, name='edit'),
    path('verify/<int:pk>/', views.integration_verify, name='verify'),
]
EOF

echo "✅ integrations/urls.py written."

# 9) Create integration templates
templates_dir="integrations/templates/integrations"
mkdir -p $templates_dir

# list.html
cat > $templates_dir/list.html << 'EOF'
{% extends "base.html" %}
{% block title %}Integrations{% endblock %}
{% block content %}
  <h2>Integrations</h2>
  <table class="table table-dark">
    <thead><tr><th>Provider</th><th>Username</th><th>Status</th><th>Actions</th></tr></thead>
    <tbody>
      {% for it in items %}
      <tr>
        <td>{{ it.get_provider_display }}</td>
        <td>{{ it.username }}</td>
        <td>
          {% if it.verified %}
            <span class="badge bg-success">Verified</span>
          {% else %}
            <span class="badge bg-danger">Unverified</span>
          {% endif %}
        </td>
        <td>
          <a class="btn btn-sm btn-primary" href="{% url 'integrations:edit' it.pk %}">Save/Update</a>
          <a class="btn btn-sm btn-warning" href="{% url 'integrations:verify' it.pk %}">Verify</a>
        </td>
      </tr>
      {% empty %}
      <tr><td colspan="4">No integrations yet.</td></tr>
      {% endfor %}
    </tbody>
  </table>
  <a class="btn btn-success" href="{% url 'integrations:add' %}">Add Integration</a>
{% endblock %}
EOF

# form.html
cat > $templates_dir/form.html << 'EOF'
{% extends "base.html" %}
{% block title %}Add/Edit Integration{% endblock %}
{% block content %}
  <h2>{{ form.instance.pk|yesno:"Edit Integration,Add Integration" }}</h2>
  <form method="post">{% csrf_token %}
    {{ form.as_p }}
    <button type="submit" class="btn btn-primary">Save</button>
  </form>
{% endblock %}
EOF

echo "✅ Integration templates created."

# 10) Inject into sidebar in base.html
grep -q "Integrations" stocknear/templates/base.html || cat >> stocknear/templates/base.html << 'EOF'
<!-- Sidebar: Integrations link -->
<li class="nav-item mb-2">
  <a class="nav-link text-light" href="{% url 'integrations:list' %}">Integrations</a>
</li>
EOF

echo "✅ Sidebar updated with Integrations link."

echo "🎉 add_integrations.sh done. Next steps:"
echo "  1) Add 'integrations' to INSTALLED_APPS in settings.py"
echo "  2) python manage.py makemigrations integrations"
echo "  3) python manage.py migrate"
echo "  4) Restart server and visit /integrations/"
