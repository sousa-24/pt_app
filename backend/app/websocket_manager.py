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
            dead_connections = []
            for connection in self.active_connections[user_id]:
                try:
                    if isinstance(message, (dict, list)):
                        await connection.send_json(message)
                    else:
                        await connection.send_text(message)
                except Exception:
                    dead_connections.append(connection)
        
        # remove dead connections
            for conn in dead_connections:
                self.active_connections[user_id].remove(conn)
        
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]


    def is_connected(self, user_id: int) -> bool:
        return bool(self.active_connections.get(user_id))

    async def broadcast(self, message: Any):
        for connections in self.active_connections.values():
            for connection in connections:
                if isinstance(message, (dict, list)):
                    await connection.send_json(message)
                else:
                    await connection.send_text(message)

manager = WebSocketManager()
