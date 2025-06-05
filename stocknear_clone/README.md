# Stocknear Clone

This is a Django-based scaffold to clone the basic functionality of Stocknear.com:
- Real-time (or near real-time) stock quotes, top movers lists.
- Market news feed.
- User authentication (with free vs. premium tiers).
- Demo templates using Bootstrap 5.

## How to run locally

1. **Activate virtualenv**  
   \`\`\`bash
   source venv/bin/activate
   \`\`\`
2. **Apply migrations & create superuser**  
   \`\`\`bash
   python manage.py migrate
   python manage.py createsuperuser
   \`\`\`
3. **Run the development server**  
   \`\`\`bash
   python manage.py runserver
   \`\`\`
4. Visit [http://localhost:8000/](http://localhost:8000/) to see the home page.

## Next Steps

- Wire up actual data-fetch tasks (e.g., Celery beat + Celery worker) to populate \`Stock\` and \`NewsItem\`.  
- Build out DRF endpoints for JSON-powered widgets (e.g., top gainers, flow feed).  
- Flesh out front-end templates & JavaScript (Chart.js) for price charts and interactive tables.

