import json
from channels.generic.websocket import AsyncWebsocketConsumer

class VoteConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("votes", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("votes", self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        await self.channel_layer.group_send(
            "votes",
            {
                "type": "send_vote",
                "votes": data["votes"],
            }
        )

    async def send_vote(self, event):
        await self.send(text_data=json.dumps({"votes": event["votes"]}))
