"""
chatbot/views.py
=================
API views for the Aawaj mental health chatbot.

Endpoints:
    POST /api/v1/chatbot/message/      → Send a message, get a bot response
    POST /api/v1/chatbot/session/new/  → Start a new session
    GET  /api/v1/chatbot/session/<id>/ → Retrieve session history
    GET  /api/v1/chatbot/health/       → Health check
"""

import os
import logging
from datetime import datetime

from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .models import ChatSession, ChatMessage
from .serializers import (
    ChatRequestSerializer,
    ChatResponseSerializer,
    ChatSessionSerializer,
)
from .chatbot_engine import AawajChatbotEngine

logger = logging.getLogger(__name__)

# ── Singleton engine (loaded once at startup) ─────────────────────────────
_engine = None

def get_engine() -> AawajChatbotEngine:
    global _engine
    if _engine is None:
        model_dir = getattr(settings, 'CHATBOT_MODEL_DIR',
                            os.path.join(settings.BASE_DIR, 'chatbot', 'ml_models'))
        _engine = AawajChatbotEngine(model_dir=model_dir)
    return _engine


# ── Views ─────────────────────────────────────────────────────────────────

class ChatMessageView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    """
    POST /api/v1/chatbot/message/
    Accepts a user message, runs intent classification,
    returns an empathetic bot response.
    """

    def post(self, request):
        serializer = ChatRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data       = serializer.validated_data
        device_id  = data['device_id']
        user_msg   = data['message'].strip()
        session_id = data.get('session_id')

        # Get or create session
        if session_id:
            try:
                session = ChatSession.objects.get(id=session_id, device_id=device_id)
            except ChatSession.DoesNotExist:
                session = ChatSession.objects.create(device_id=device_id)
        else:
            session = ChatSession.objects.create(device_id=device_id)

        # Save user message
        ChatMessage.objects.create(
            session=session,
            role='user',
            content=user_msg,
        )

        # Run chatbot engine
        try:
            engine = get_engine()
            result = engine.get_response(user_msg)
        except Exception as e:
            logger.error(f"Chatbot engine error: {e}")
            return Response(
                {"error": "Chatbot service temporarily unavailable."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        # Save bot message
        bot_msg = ChatMessage.objects.create(
            session=session,
            role='bot',
            content=result['message'],
            intent=result['intent'],
            confidence=result['confidence'],
            is_crisis=result['is_crisis'],
        )

        # Crisis escalation log
        if result['is_crisis']:
            logger.warning(
                f"[CRISIS DETECTED] device={device_id} session={session.id} "
                f"confidence={result['confidence']:.2f} msg='{user_msg[:80]}'"
            )

        response_data = {
            "session_id": session.id,
            "intent":     result['intent'],
            "confidence": result['confidence'],
            "message":    result['message'],
            "is_crisis":  result['is_crisis'],
            "exercise":   result.get('exercise'),
            "timestamp":  bot_msg.timestamp,
        }

        return Response(
            ChatResponseSerializer(response_data).data,
            status=status.HTTP_200_OK
        )


class NewSessionView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    """
    POST /api/v1/chatbot/session/new/
    Creates a new chat session and returns the session id + greeting.
    """

    def post(self, request):
        device_id = request.data.get('device_id', '')
        if not device_id:
            return Response({"error": "device_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        session = ChatSession.objects.create(device_id=device_id)

        # Get greeting from engine
        try:
            engine  = get_engine()
            result  = engine.get_response("hello")
        except Exception:
            result = {
                "intent": "greeting",
                "confidence": 1.0,
                "message": "Hello 💙 I'm Aawaj Support — a safe space to share how you're feeling. How are you doing today?",
                "is_crisis": False,
                "exercise": None,
            }

        bot_msg = ChatMessage.objects.create(
            session=session,
            role='bot',
            content=result['message'],
            intent='greeting',
            confidence=1.0,
            is_crisis=False,
        )

        return Response({
            "session_id": session.id,
            "message":    result['message'],
            "intent":     "greeting",
            "is_crisis":  False,
            "exercise":   None,
            "timestamp":  bot_msg.timestamp,
        }, status=status.HTTP_201_CREATED)


class SessionHistoryView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    """
    GET /api/v1/chatbot/session/<session_id>/
    Returns the full message history for a session.
    """

    def get(self, request, session_id):
        device_id = request.query_params.get('device_id', '')
        try:
            session = ChatSession.objects.get(id=session_id, device_id=device_id)
        except ChatSession.DoesNotExist:
            return Response({"error": "Session not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = ChatSessionSerializer(session)
        return Response(serializer.data)


class HealthCheckView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    """
    GET /api/v1/chatbot/health/
    Simple health check — confirms model is loaded.
    """

    def get(self, request):
        try:
            engine  = get_engine()
            intents = engine.classes
            return Response({
                "status":  "ok",
                "model":   "AawajChatbot v1.0",
                "intents": intents,
            })
        except Exception as e:
            return Response({"status": "error", "detail": str(e)},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)
