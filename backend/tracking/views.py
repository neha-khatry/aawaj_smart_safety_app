from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import TrackingSession
from django.shortcuts import render
from rest_framework.permissions import AllowAny

@api_view(['POST'])
@permission_classes([AllowAny])
def create_session(request):
    session = TrackingSession.objects.create()
    return Response({"token": str(session.token)})

@api_view(['POST'])
@permission_classes([AllowAny])
def update_location(request):
    token = request.data.get("token")
    lat = request.data.get("latitude")
    lon = request.data.get("longitude")

    session = TrackingSession.objects.get(token=token)
    session.latitude = lat
    session.longitude = lon
    session.save()

    return Response({"status": "updated"})

@api_view(['GET'])
@permission_classes([AllowAny])
def get_location(request, token):
    session = TrackingSession.objects.get(token=token)
    return Response({
        "latitude": session.latitude,
        "longitude": session.longitude
    })

def track_page(request, token):
    return render(request, "track.html", {"token": token})