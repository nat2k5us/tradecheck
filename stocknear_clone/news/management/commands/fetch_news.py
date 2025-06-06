import feedparser
from urllib.parse import urlparse
from datetime import datetime, timezone
from django.core.management.base import BaseCommand
from news.models import NewsItem

# List of RSS feed URLs to pull from
RSS_SOURCES = [
    "https://www.reutersagency.com/feed/?best-topics=business-finance-market-news",  # Reuters Market News
    "https://www.cnbc.com/id/100003114/device/rss/rss.html",                         # CNBC Top News & Analysis
    "https://seekingalpha.com/market_currents.xml",                                  # Seeking Alpha Market Currents
]

class Command(BaseCommand):
    help = "Fetch latest items from predefined RSS feeds and store into NewsItem."

    def handle(self, *args, **options):
        for feed_url in RSS_SOURCES:
            self.stdout.write(f"Pulling feed: {feed_url}")
            feed = feedparser.parse(feed_url)
            for entry in feed.entries:
                # Assume 'published_parsed' exists; fallback to now if missing
                if hasattr(entry, "published_parsed"):
                    published_dt = datetime.fromtimestamp(
                        datetime(
                            *entry.published_parsed[:6]
                        ).timestamp(),
                        tz=timezone.utc
                    )
                else:
                    published_dt = datetime.now(timezone.utc)

                link = entry.get("link", "").strip()
                title = entry.get("title", "").strip()
                if not link or not title:
                    continue

                domain = urlparse(link).netloc

                # Avoid duplicates by URL
                if NewsItem.objects.filter(url=link).exists():
                    continue

                # Create new NewsItem
                NewsItem.objects.create(
                    headline=title,
                    url=link,
                    timestamp=published_dt,
                    source=domain,
                )
                self.stdout.write(f"  • Added: {title[:60]}...")

        self.stdout.write(self.style.SUCCESS("Done fetching RSS items."))
