from rest_framework import serializers
from .models import Checkin


class CheckinSerializer(serializers.ModelSerializer):
    class Meta:
        model = Checkin
        fields = ['id', 'scheduled_at', 'responded_at',
                  'is_safe', 'mood', 'message']
