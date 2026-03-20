from django.core.management.base import BaseCommand
from django.utils import timezone
from checkin.models import Checkin


class Command(BaseCommand):
    help = 'Detects missed check-ins and notifies users'

    def handle(self, *args, **kwargs):
        missed = Checkin.objects.filter(
            responded_at__isnull=True, confirmed_at__lte=timezone.now()-timezone.timedelta(hours=24))
        for checkin in missed:
            # Replace print with email or push notification
            self.stdout.write(f"Missed check-in for {checkin.user.username}")
