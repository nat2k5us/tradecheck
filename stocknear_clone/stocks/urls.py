from django.urls import path
from . import views

app_name = 'stocks'

urlpatterns = [
    # Market movers and search
    path('', views.stock_list, name='list'),
    path('search/', views.stock_search, name='search'),

    # Stubs for overview and ETF
    path('overview/', views.stock_overview, name='overview'),
    path('etf/', views.etf_list, name='etf'),

    # Calendar routes
    path('calendar/dividends/', views.calendar_dividends, name='calendar_dividends'),
    path('calendar/earnings/', views.calendar_earnings, name='calendar_earnings'),
    path('calendar/ipo/', views.calendar_ipo, name='calendar_ipo'),
    path('calendar/economic/', views.calendar_economic, name='calendar_economic'),

    # Detail by symbol
    path('<str:symbol>/', views.stock_detail, name='detail'),
]
