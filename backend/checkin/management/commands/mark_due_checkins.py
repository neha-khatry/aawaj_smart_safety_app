from django.core.management.base import BaseCommand
from django.utils import timezone
from checkin.models import Checkin


class Command(BaseCommand):
    help = "Marks pending check-ins as DUE when scheduled time arrives."

    def handle(self, *args, **kwargs):
        now = timezone.now()

        due_qs = Checkin.objects.filter(
            status="pending",
            scheduled_at__lte=now
        )

        count = due_qs.count()

        for checkin in due_qs:
            checkin.status = "due"
            checkin.save(update_fields=["status"])
            print(f"⏰ CHECKIN DUE: {checkin.id}")

        self.stdout.write(self.style.SUCCESS(f"Done. Marked due: {count}"))
