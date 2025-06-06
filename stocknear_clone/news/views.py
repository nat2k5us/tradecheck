from django.shortcuts import render
from django.utils.timesince import timesince
from .models import NewsItem

def news_feed(request):
    """
    Show most recent news items, ordered newest-first. 
    Annotate each item with 'time_ago' for display.
    """
    items = NewsItem.objects.order_by("-timestamp")[:50]
    # Annotate a 'time_ago' string for each item
    for item in items:
        item.time_ago = timesince(item.timestamp) + " ago"
    return render(request, "news/news_feed.html", {"items": items})
