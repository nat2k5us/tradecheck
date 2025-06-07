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
