from rest_framework import serializers
from .models import EmergencyContact

class AudioUploadSerializer(serializers.Serializer):
    audio_file = serializers.FileField()

class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = '__all__'