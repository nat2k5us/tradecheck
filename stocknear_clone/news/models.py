from django.db import models

class NewsItem(models.Model):
    headline = models.CharField(max_length=500)
    url = models.URLField()
    timestamp = models.DateTimeField()

    def __str__(self):
        return self.headline
