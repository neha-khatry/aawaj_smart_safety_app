from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import AudioUploadSerializer
from .utils import predict_scream
import os
from .models import EmergencyContact, Device
from .serializers import EmergencyContactSerializer
from .dialogpt import generate_reply
from .twilo_service import send_sos_sms
from .models import SosAudio

class SVMDetectAPIView(APIView):
    def post(self, request, format=None):
        serializer = AudioUploadSerializer(data=request.data)
        if serializer.is_valid():
            audio = serializer.validated_data['audio_file']
            # Save temporarily
            temp_path = os.path.join("media", audio.name)
            with open(temp_path, 'wb') as f:
                for chunk in audio.chunks():
                    f.write(chunk)
            # Predict
            result = predict_scream(temp_path)
            # Optional: delete file
            os.remove(temp_path)
            return Response(result)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class SaveEmergencyContact(APIView):
    def post(self, request):
        device_id = request.data.get('device_id')

        if not device_id:
            return Response({"error": "device_id required"}, status=400)

        Device.objects.get_or_create(device_id=device_id)

        serializer = EmergencyContactSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)

        return Response(serializer.errors, status=400)
    
class GetEmergencyContacts(APIView):
    def post(self, request):
        device_id = request.data.get('device_id')

        if not device_id:
            return Response(
                {"error": "device_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        contacts = EmergencyContact.objects.filter(device_id=device_id)
        serializer = EmergencyContactSerializer(contacts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    

class TriggerSOSView(APIView):
    def post(self, request):
        device_id = request.data.get("device_id")

        if not device_id:
            return Response(
                {"error": "device_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Fetch emergency contacts for the device
        contacts = EmergencyContact.objects.filter(device_id=device_id)

        if not contacts.exists():
            return Response(
                {"error": "No emergency contacts found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Simple SOS message
        message = (
            "🚨 SOS ALERT!\n"
           
        )

        sent_count = 0
        failed = []

        for contact in contacts:
            try:
                send_sos_sms(contact.phone_number, message)
                sent_count += 1
            except Exception as e:
                failed.append({
                    "name": contact.name,
                    "phone": contact.phone_number,
                    "error": str(e)
                })

        return Response(
            {
                "status": "SOS processed",
                "sent_count": sent_count,
                "failed": failed
            },
            status=status.HTTP_200_OK
        )

class MentalSupportAPIView(APIView):
    def post(self, request):
        message = request.data.get("message")

        if not message:
            return Response(
                {"error": "Message is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        safe_prompt = (
            "You are a calm, kind emotional support assistant. "
            "You do not give medical or legal advice. "
            "You encourage contacting trusted people or emergency services if the user is in danger.\n\n"
            f"User: {message}\nAssistant:"
        )

        reply = generate_reply(safe_prompt)

        return Response({"reply": reply})
    

class SaveAudioMetadataView(APIView):
    """
    API to save SOS audio metadata to PostgreSQL.
    Expects JSON:
    {
        "device_id": "uuid",
        "local_path": "/path/to/file",
        "created_at": "2026-01-25T12:00:00Z"
    }
    """

    def post(self, request, *args, **kwargs):
        try:
            device_id = request.data.get('device_id')
            local_path = request.data.get('local_path')
            #created_at = request.data.get('created_at')

            if not device_id or not local_path:
                return Response(
                    {"error": "device_id and local_path are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create record
            SosAudio.objects.create(
                device_id=device_id,
                local_path=local_path,
                #created_at=created_at
            )

            return Response({"status": "success"}, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import EmergencyContact

class DeleteContactView(APIView):

    def delete(self, request, contact_id):
        try:
            device_id = request.query_params.get('device_id')

            if not device_id:
                return Response(
                    {"error": "device_id is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            contact = EmergencyContact.objects.get(
                id=contact_id,
                device_id=device_id
            )

            contact.delete()

            return Response(
                {"message": "Contact deleted successfully"},
                status=status.HTTP_200_OK
            )

        except EmergencyContact.DoesNotExist:
            return Response(
                {"error": "Contact not found"},
                status=status.HTTP_404_NOT_FOUND
            )
