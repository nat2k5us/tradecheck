from django.contrib import admin
from .models import Stock

@admin.register(Stock)
class StockAdmin(admin.ModelAdmin):
    list_display = ('symbol', 'name', 'last_price', 'change_percent')
    search_fields = ('symbol', 'name')
