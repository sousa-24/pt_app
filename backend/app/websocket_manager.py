from fastapi import WebSocket
from typing import Any, Dict, List

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections.setdefault(user_id, []).append(websocket)

    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in self.active_connections:
            self.active_connections[user_id] = [conn for conn in self.active_connections[user_id] if conn != websocket]
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_message(self, message: Any, user_id: int):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                if isinstance(message, (dict, list)):
                    await connection.send_json(message)
                else:
                    await connection.send_text(message)

    async def broadcast(self, message: Any):
        for connections in self.active_connections.values():
            for connection in connections:
                if isinstance(message, (dict, list)):
                    await connection.send_json(message)
                else:
                    await connection.send_text(message)

manager = WebSocketManager()
