"""
chatbot/models.py
==================
Django ORM models for the Aawaj mental health chatbot.
"""

from django.db import models


class ChatSession(models.Model):
    """Represents a single user chatbot session."""
    device_id   = models.CharField(max_length=255, db_index=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)
    is_active   = models.BooleanField(default=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Session [{self.device_id}] @ {self.created_at:%Y-%m-%d %H:%M}"


class ChatMessage(models.Model):
    """Individual messages within a chat session."""

    ROLE_CHOICES = [
        ('user', 'User'),
        ('bot',  'Bot'),
    ]

    session    = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    role       = models.CharField(max_length=10, choices=ROLE_CHOICES)
    content    = models.TextField()
    intent     = models.CharField(max_length=50, blank=True, null=True)   # only for bot messages
    confidence = models.FloatField(null=True, blank=True)                 # model confidence
    is_crisis  = models.BooleanField(default=False)
    timestamp  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"[{self.role.upper()}] {self.content[:60]}"
