import os
import requests
from django.shortcuts import render, redirect
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
        stock_data = data[0]  # first (and only) element
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
