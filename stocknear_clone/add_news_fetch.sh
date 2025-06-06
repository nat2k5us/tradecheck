#!/usr/bin/env bash
#
# add_news_fetch.sh
#
# This script adds RSS‐based population of the News page, preserving a format similar to
# Stocknear’s “Market News” section. Specifically, it:
#
#   1. Installs `feedparser` into requirements.txt (if not already present).
#   2. Creates a Django management command at `news/management/commands/fetch_news.py` that:
#        • Pulls headlines from a list of RSS feeds (e.g., Reuters, CNBC, SeekingAlpha).
#        • Parses title, link, published timestamp, and source domain.
#        • Writes them into the `NewsItem` model (avoiding duplicates by URL).
#   3. Updates `news/views.py` to order items newest-first and pass “source” to the template.
#   4. Overwrites `news/templates/news/news_feed.html` to render each item in a styled list:
#        • Show “X minutes ago” or “X hours ago” after the headline.
#        • Show source domain.
#   5. Reminds you to run `python manage.py migrate` (if needed) and `python manage.py fetch_news`
#      to populate the database.
#
# You can safely run this script multiple times; it overwrites files with idempotent content.
#
# Usage:
#   cd <project-root-containing-manage.py>
#   chmod +x add_news_fetch.sh
#   ./add_news_fetch.sh
#

set -euo pipefail

# 1) Verify we’re in the Django project root (manage.py must exist)
if [[ ! -f "./manage.py" ]]; then
  echo "❌  Error: manage.py not found in $(pwd)."
  echo "    Run this from your Django project root."
  exit 1
fi

# 2) Activate virtualenv if present
VENV_DIR="./venv"
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ -f "${ACTIVATE_SCRIPT}" ]]; then
  # shellcheck disable=SC1091
  source "${ACTIVATE_SCRIPT}"
  echo "🟢  Activated virtualenv."
else
  echo "⚠️   Warning: Virtualenv not found at ${ACTIVATE_SCRIPT}. Continuing without activation."
fi

# 3) Ensure feedparser is in requirements.txt
REQS="requirements.txt"
if ! grep -q "^feedparser" "${REQS}" 2>/dev/null; then
  echo "🔄  Adding feedparser to ${REQS}..."
  echo "feedparser>=6.0.0" >> "${REQS}"
  # Install it immediately
  pip install feedparser
else
  echo "ℹ️   feedparser already in ${REQS}, skipping."
fi

# 4) Create the management command directory if not exists
CMD_DIR="news/management/commands"
echo "🔧  Ensuring ${CMD_DIR} directory exists..."
mkdir -p "${CMD_DIR}"
touch "news/management/__init__.py"
touch "news/management/commands/__init__.py"

# 5) Write the fetch_news management command
FETCH_CMD="news/management/commands/fetch_news.py"
echo "✏️  Overwriting ${FETCH_CMD} with RSS fetching logic..."
cat > "${FETCH_CMD}" << 'EOF'
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
EOF

# 6) Update news/models.py to ensure it has a 'source' field
MODELS_FILE="news/models.py"
echo "✏️  Ensuring news/models.py has a 'source' field..."
# Overwrite the NewsItem model with a source CharField
cat > "${MODELS_FILE}" << 'EOF'
from django.db import models

class NewsItem(models.Model):
    headline = models.CharField(max_length=500)
    url = models.URLField(unique=True)
    timestamp = models.DateTimeField()
    source = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return self.headline
EOF

# 7) Overwrite news/views.py to order items newest-first and pass them to template
VIEWS_FILE="news/views.py"
echo "✏️  Overwriting ${VIEWS_FILE} to order by timestamp descending..."
cat > "${VIEWS_FILE}" << 'EOF'
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
EOF

# 8) Overwrite news/templates/news/news_feed.html to match Stocknear’s format
TEMPLATE_DIR="news/templates/news"
TEMPLATE_FILE="${TEMPLATE_DIR}/news_feed.html"
echo "🔧  Ensuring directory ${TEMPLATE_DIR} exists..."
mkdir -p "${TEMPLATE_DIR}"

echo "✏️  Overwriting ${TEMPLATE_FILE} with structured format..."
cat > "${TEMPLATE_FILE}" << 'EOF'
{% extends "base.html" %}
{% block title %}Market News{% endblock %}

{% block content %}
  <div class="row">
    <div class="col-md-8 offset-md-2">
      <h2 class="mb-4 text-center">Market News</h2>
      <ul class="list-group">
        {% for n in items %}
          <li class="list-group-item bg-dark text-light d-flex justify-content-between align-items-start">
            <div>
              <a href="{{ n.url }}" target="_blank" class="fw-bold text-info">
                {{ n.headline }}
              </a>
              <div class="small text-muted mt-1">
                {{ n.time_ago }} &middot; {{ n.source }}
              </div>
            </div>
            <span class="badge bg-secondary rounded-pill">
              {{ forloop.counter }}
            </span>
          </li>
        {% empty %}
          <li class="list-group-item bg-dark text-light text-center">
            No news available.
          </li>
        {% endfor %}
      </ul>
    </div>
  </div>
{% endblock %}
EOF

# 9) Remind to make migrations and fetch news
echo
echo "🎉  add_news_fetch.sh completed."
echo "  • Now run:"
echo "      python manage.py makemigrations"
echo "      python manage.py migrate"
echo "      python manage.py fetch_news"
echo "      python manage.py runserver"
echo
echo "Visit http://127.0.0.1:8000/news/ to see the populated Market News page."
