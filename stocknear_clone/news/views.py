from django.shortcuts import render
from .models import NewsItem

def news_feed(request):
    # Placeholder: show most recent news items
    items = NewsItem.objects.order_by('-timestamp')[:50]
    return render(request, 'news/news_feed.html', {'items': items})
