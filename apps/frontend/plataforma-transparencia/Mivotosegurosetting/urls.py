"""
URL configuration for Mivotoseguro_app project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from votoseguro_app.views import landing_page , votacion , identidad , informate, consultar_datos ,login_view
from django.conf import settings

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', landing_page, name='landing'),
    path('votacion', votacion, name='votacion'),
    path('identidad', identidad, name='identidad'),
    path('informate', informate, name='informate'),
    path('consultar_datos/', consultar_datos, name='consultar_datos'),
    path('login/', login_view, name='login'),

]
