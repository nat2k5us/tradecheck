from django.db import models
from django.contrib.auth import get_user_model

PROVIDER_CHOICES = [
    ('webull', 'Webull'),
    ('robinhood', 'Robinhood'),
    ('fidelity', 'Fidelity'),
]

User = get_user_model()

class Integration(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    provider = models.CharField(max_length=32, choices=PROVIDER_CHOICES)
    username = models.CharField(max_length=255)
    key_name = models.CharField(max_length=255, help_text="Keyring item name")  # used by keyring
    verified = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'provider')

    def __str__(self):
        return f"{self.user} – {self.provider}"
