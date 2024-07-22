import boto3
import json
import os

def handler(event, context):
    # chat_room.messagesを取得
    print(event)
    
    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from get_messages!"
        }
    }
