from django.urls import path
from . import views

urlpatterns = [
    path('create/', views.create_session),
    path('update/', views.update_location),
    path('get/<str:token>/', views.get_location),
    path('track/<str:token>/', views.track_page),
]