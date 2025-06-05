from django.db import models

class Stock(models.Model):
    symbol = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=255)
    last_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    change_percent = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.symbol} - {self.name}"
