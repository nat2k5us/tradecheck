from rest_framework import serializers
from .models import Stock

class StockSerializer(serializers.ModelSerializer):
    class Meta:
        model = Stock
        fields = ['symbol', 'name', 'last_price', 'change_percent']
