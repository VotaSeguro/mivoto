import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from channels.layers import get_channel_layer
from django.urls import re_path
from votoseguro_app.consumers import VoteConsumer  # Reemplaza 'miapp' con el nombre de tu aplicación

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "Mivotosegurosetting.settings")  

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter([
            re_path(r"ws/votes/$", VoteConsumer.as_asgi()),  # Ruta WebSocket directa
        ])
    ),
})
