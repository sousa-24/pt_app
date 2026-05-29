#Espaço para criar funções

#Função para criar uma notificação para um utilizador específico, usada para alertas e mensagens importantes dentro da aplicação.
from sqlalchemy.orm import Session
from app import models

def create_notifiation(db:Session, user_id:int, title:str, message: str):
    notification = models.Notification(
        user_id= user_id,
        title= title,
        content= message
    )
    db.add(notification)
    db.commit()