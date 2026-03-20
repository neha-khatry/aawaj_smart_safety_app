from django.db import models

class Device(models.Model):
    device_id = models.CharField(max_length=255, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.device_id


class EmergencyContact(models.Model):
    device_id = models.CharField(max_length=255)
    name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=20)
    relation = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.phone_number}"

class SosAudio(models.Model):
    device_id = models.CharField(max_length=100)
    local_path = models.TextField()
    audio_url = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)