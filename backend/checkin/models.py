from django.db import models
from django.utils import timezone


class Checkin(models.Model):
    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("due", "Due"),
        ("confirmed", "Confirmed"),
        ("missed", "Missed"),
        ("cancelled", "Cancelled"),
    )

    # if you removed login, keep user optional
    user = models.ForeignKey(
        "auth.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    scheduled_at = models.DateTimeField()
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="pending")

    is_safe = models.BooleanField(null=True, blank=True)
    mood = models.CharField(max_length=50, null=True, blank=True)
    message = models.TextField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    responded_at = models.DateTimeField(null=True, blank=True)  # ✅ MUST HAVE
