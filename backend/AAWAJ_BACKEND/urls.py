
from django.contrib import admin
from django.urls import path,include
from scream_detector.views import DeleteContactView, SVMDetectAPIView, SaveEmergencyContact, GetEmergencyContacts,TriggerSOSView,MentalSupportAPIView,SaveAudioMetadataView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/detect_scream/', SVMDetectAPIView.as_view(), name='detect-scream'),
    path('api/save_contact/', SaveEmergencyContact.as_view()),
    path('api/get_contacts/', GetEmergencyContacts.as_view()),
    #path('api/trigger_sos/', TriggerSOSView.as_view(), name="trigger-sos"),
    path('api/mental_support/', MentalSupportAPIView.as_view(), name="mental_support"),
    path('api/save_audio/', SaveAudioMetadataView.as_view(), name='save_audio'),
    path('api/contacts/delete/<int:contact_id>/', DeleteContactView.as_view(),name='delete-contact'),
    path("api/v1/checkin/", include("checkin.urls")),
    path("api/v1/auth/token/", TokenObtainPairView.as_view(),
         name="token_obtain_pair"),
    path("api/v1/auth/token/refresh/",
         TokenRefreshView.as_view(), name="token_refresh"),
]
