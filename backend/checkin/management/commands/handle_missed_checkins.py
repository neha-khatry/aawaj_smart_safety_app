from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

from checkin.models import Checkin


class Command(BaseCommand):
    help = "Marks due check-ins as MISSED after grace period if user did not respond."

    def handle(self, *args, **kwargs):
        now = timezone.now()
        grace_deadline = now - timedelta(minutes=3)

        missed_qs = Checkin.objects.filter(
            status="due",
            responded_at__isnull=True,
            scheduled_at__lte=grace_deadline
        )

        count = missed_qs.count()

        for checkin in missed_qs:
            checkin.status = "missed"
            checkin.responded_at = now
            checkin.is_safe = False
            checkin.message = checkin.message or "No response from user (auto missed)."
            checkin.save()

            print(f"🚨 AUTO MISSED CHECKIN: {checkin.id}")

        self.stdout.write(self.style.SUCCESS(f"Done. Auto-missed: {count}"))
