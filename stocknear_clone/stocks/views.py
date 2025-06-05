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
