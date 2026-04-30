"""
phrase_detector/views.py
=========================
REST API views for Aawaj phrase detection.

Endpoints:
    POST /api/v1/phrase/detect/   → Classify transcribed text
    GET  /api/v1/phrase/health/   → Health check
    GET  /api/v1/phrase/keywords/ → List all emergency keywords
"""

import os
import logging
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .models import PhraseDetectionEvent
from .phrase_engine import PhraseDetectionEngine, ALL_KEYWORDS

logger = logging.getLogger(__name__)

# ── Singleton engine ────────────────────────────────────────────────────
_engine = None

def get_engine() -> PhraseDetectionEngine:
    global _engine
    if _engine is None:
        model_dir = getattr(
            settings, "PHRASE_MODEL_DIR",
            os.path.join(settings.BASE_DIR, "phrase_detector", "ml_models")
        )
        _engine = PhraseDetectionEngine(model_dir=model_dir)
    return _engine


# ── Views ────────────────────────────────────────────────────────────────

class PhraseDetectView(APIView):
    """
    POST /api/v1/phrase/detect/
    Accepts transcribed speech text, returns emergency classification.

    Request body:
        {
          "device_id": "abc123",
          "text": "bachau malaai",
          "auto_sos": true   (optional — whether to mark SOS triggered)
        }

    Response:
        {
          "is_emergency": true,
          "confidence": 0.985,
          "method": "ml",
          "matched_keyword": "bachau",
          "text": "bachau malaai",
          "event_id": 42
        }
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        device_id = request.data.get("device_id", "")
        text      = request.data.get("text", "").strip()
        auto_sos  = request.data.get("auto_sos", False)

        if not text:
            return Response(
                {"error": "text field is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            engine = get_engine()
            result = engine.classify(text)
        except Exception as e:
            logger.error(f"Phrase engine error: {e}")
            return Response(
                {"error": "Phrase detection service unavailable."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        # Log event
        event = PhraseDetectionEvent.objects.create(
            device_id       = device_id,
            text            = text,
            processed_text  = result["processed"],
            is_emergency    = result["is_emergency"],
            confidence      = result["confidence"],
            method          = result["method"],
            matched_keyword = result["matched_keyword"],
            sos_triggered   = auto_sos and result["is_emergency"],
        )

        if result["is_emergency"]:
            logger.warning(
                f"[PHRASE EMERGENCY] device={device_id} "
                f"text='{text[:80]}' "
                f"confidence={result['confidence']:.2f} "
                f"keyword={result['matched_keyword']} "
                f"method={result['method']}"
            )

        return Response({
            "is_emergency":    result["is_emergency"],
            "confidence":      result["confidence"],
            "method":          result["method"],
            "matched_keyword": result["matched_keyword"],
            "text":            text,
            "event_id":        event.id,
        }, status=status.HTTP_200_OK)


class PhraseHealthView(APIView):
    """GET /api/v1/phrase/health/"""
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        try:
            engine = get_engine()
            return Response({
                "status":    "ok",
                "model":     "AawajPhraseDetector v1.0",
                "classes":   list(engine.le.classes_),
                "threshold": 0.60,
                "languages": ["English", "Nepali (Romanized)"],
            })
        except Exception as e:
            return Response(
                {"status": "error", "detail": str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class PhraseKeywordsView(APIView):
    """GET /api/v1/phrase/keywords/ — Returns all emergency keywords."""
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({
            "total":    len(ALL_KEYWORDS),
            "keywords": ALL_KEYWORDS,
        })
