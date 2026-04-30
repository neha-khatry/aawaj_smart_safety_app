"""
phrase_detector/urls.py
========================
Add to your project's main urls.py:
    path('api/v1/phrase/', include('phrase_detector.urls')),
"""

from django.urls import path
from .views import PhraseDetectView, PhraseHealthView, PhraseKeywordsView

urlpatterns = [
    path("detect/",   PhraseDetectView.as_view(),   name="phrase-detect"),
    path("health/",   PhraseHealthView.as_view(),   name="phrase-health"),
    path("keywords/", PhraseKeywordsView.as_view(), name="phrase-keywords"),
]
