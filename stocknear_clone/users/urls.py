from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('register/', views.register_view, name='register'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('change-password/', views.change_password_view, name='change_password'),
    path(
        'change-password/done/',
        views.change_password_done_view,
        name='password_change_done'
    ),
]
