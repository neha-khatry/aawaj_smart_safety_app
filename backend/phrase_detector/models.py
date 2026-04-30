"""
phrase_detector/models.py
==========================
Django ORM models for phrase detection events.
"""

from django.db import models


class PhraseDetectionEvent(models.Model):
    """Logs each phrase detection event for monitoring and analytics."""

    METHOD_CHOICES = [
        ("ml",           "ML Classification"),
        ("keyword_boost","Keyword Boost"),
        ("keyword_only", "Keyword Only Fallback"),
    ]

    device_id        = models.CharField(max_length=255, db_index=True)
    text             = models.TextField()
    processed_text   = models.TextField(blank=True)
    is_emergency     = models.BooleanField(default=False)
    confidence       = models.FloatField(default=0.0)
    method           = models.CharField(max_length=20, choices=METHOD_CHOICES, default="ml")
    matched_keyword  = models.CharField(max_length=100, blank=True, null=True)
    sos_triggered    = models.BooleanField(default=False)
    timestamp        = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-timestamp"]

    def __str__(self):
        status = "🆘 EMERGENCY" if self.is_emergency else "✓ safe"
        return f"[{status}] device={self.device_id} | '{self.text[:50]}' | {self.confidence:.1%}"
