from datetime import timedelta
from django.utils import timezone
from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Checkin
from .serializers import CheckinSerializer

# --- List all check-ins ---


class CheckinListView(generics.ListAPIView):
    serializer_class = CheckinSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Checkin.objects.all().order_by('-scheduled_at')


# --- Schedule new check-in ---
class CheckinScheduleView(generics.CreateAPIView):
    serializer_class = CheckinSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        serializer.save()


# --- Confirm check-in ---
class CheckinConfirmView(generics.UpdateAPIView):
    serializer_class = CheckinSerializer
    permission_classes = [permissions.AllowAny]
    queryset = Checkin.objects.all()

    def perform_update(self, serializer):
        serializer.save(responded_at=timezone.now())


# --- List pending/due check-ins ---
class CheckinPendingView(generics.ListAPIView):
    serializer_class = CheckinSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        now = timezone.now()

        # Mark pending check-ins as due if time has passed
        Checkin.objects.filter(
            scheduled_at__lte=now,
            status='pending'
        ).update(status='due')

        return Checkin.objects.filter(
            status='due',
            responded_at__isnull=True
        )


# --- Trigger SOS for a due check-in ---
class TriggerSOSView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            checkin = Checkin.objects.get(
                pk=pk, status="due", responded_at__isnull=True)
        except Checkin.DoesNotExist:
            return Response({"error": "No due check-in found"}, status=404)

        # TODO: Replace with real trusted contacts from your system
        phones = ["+9779800000000"]
        message = "SOS! I am not safe."

        # Update check-in status to alerted
        checkin.status = "alerted"
        checkin.responded_at = timezone.now()
        checkin.save()

        return Response({"success": True, "phones": phones, "message": message})
