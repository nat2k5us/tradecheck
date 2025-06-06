from django.db import models

class NewsItem(models.Model):
    headline = models.CharField(max_length=500)
    url = models.URLField(unique=True)
    timestamp = models.DateTimeField()
    source = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return self.headline
