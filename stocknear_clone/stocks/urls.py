from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    path('', views.stock_list, name='list'),
    path('search/', views.stock_search, name='search'),
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
