from celery import shared_task
from django.utils import timezone
from .models import Checkin
from users.models import User


@shared_task
def send_daily_checkin():
    """
    Sends a daily check-in reminder to all users.
    """
    users = User.objects.filter(is_active=True)
    for user in users:
        # Create a new checkin entry for each user
        Checkin.objects.create(user=user)
        print(f"Check-in created for {user.username}")


@shared_task
def detect_missed_checkins():
    """
    Detects check-ins that are not responded to within 24 hours.
    """
    missed = Checkin.objects.filter(
        responded_at__isnull=True, confirmed_at__lte=timezone.now()-timezone.timedelta(hours=24))
    for checkin in missed:
        # Here you can trigger notifications or alerts
        print(f"Missed check-in detected for {checkin.user.username}")
