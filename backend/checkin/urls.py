from django.urls import path
from .views import (
    CheckinListView,
    CheckinScheduleView,
    CheckinConfirmView,
    CheckinPendingView,
    TriggerSOSView,
)

urlpatterns = [
    path("", CheckinListView.as_view(), name="checkin-list"),
    path("schedule/", CheckinScheduleView.as_view(), name="checkin-schedule"),
    path("confirm/<uuid:pk>/", CheckinConfirmView.as_view(), name="checkin-confirm"),
    path("pending/", CheckinPendingView.as_view(), name="checkin-pending"),
    path("trigger-sos/<uuid:pk>/", TriggerSOSView.as_view(),
         name="checkin-trigger-sos"),
]
