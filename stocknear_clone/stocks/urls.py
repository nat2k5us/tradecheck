from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    # List and search come first
    path('', views.stock_list, name='list'),
    path('search/', views.stock_list, name='search'),

    # Overview and ETF must come before the symbol-based detail
    path('overview/', views.stock_overview, name='overview'),
    path('etf/', views.etf_list, name='etf'),

    # Finally, detail by symbol
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
