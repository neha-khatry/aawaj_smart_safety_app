"""
chatbot/serializers.py
========================
DRF serializers for the Aawaj chatbot API.
"""

from rest_framework import serializers
from .models import ChatSession, ChatMessage


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ChatMessage
        fields = ['id', 'role', 'content', 'intent', 'confidence', 'is_crisis', 'timestamp']


class ChatSessionSerializer(serializers.ModelSerializer):
    messages = ChatMessageSerializer(many=True, read_only=True)

    class Meta:
        model  = ChatSession
        fields = ['id', 'device_id', 'created_at', 'updated_at', 'is_active', 'messages']


# ── Request / Response Serializers ──────────────────────────────────────────

class ChatRequestSerializer(serializers.Serializer):
    """Incoming message from the Flutter app."""
    device_id  = serializers.CharField(max_length=255)
    message    = serializers.CharField(max_length=1000)
    session_id = serializers.IntegerField(required=False, allow_null=True)


class ChatResponseSerializer(serializers.Serializer):
    """Outgoing chatbot response to the Flutter app."""
    session_id = serializers.IntegerField()
    intent     = serializers.CharField()
    confidence = serializers.FloatField()
    message    = serializers.CharField()
    is_crisis  = serializers.BooleanField()
    exercise   = serializers.DictField(required=False, allow_null=True)
    timestamp  = serializers.DateTimeField()
