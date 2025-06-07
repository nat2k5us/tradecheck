from django.urls import path
from . import views

app_name = 'integrations'
urlpatterns = [
    path('', views.integration_list, name='list'),
    path('add/', views.integration_edit, name='add'),
    path('edit/<int:pk>/', views.integration_edit, name='edit'),
    path('verify/<int:pk>/', views.integration_verify, name='verify'),
]
