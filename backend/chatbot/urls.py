"""
chatbot/urls.py
================
URL routing for the Aawaj mental health chatbot API.

Add to your project's main urls.py:
    path('api/v1/chatbot/', include('chatbot.urls')),
"""

from django.urls import path
from .views import (
    ChatMessageView,
    NewSessionView,
    SessionHistoryView,
    HealthCheckView,
)

urlpatterns = [
    # Send a message → get bot response
    path('message/',            ChatMessageView.as_view(),   name='chatbot-message'),

    # Start a new chat session
    path('session/new/',        NewSessionView.as_view(),    name='chatbot-new-session'),

    # Retrieve history for a session
    path('session/<int:session_id>/', SessionHistoryView.as_view(), name='chatbot-session'),

    # Health check
    path('health/',             HealthCheckView.as_view(),   name='chatbot-health'),
]
