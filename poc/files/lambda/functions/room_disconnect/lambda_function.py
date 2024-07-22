import json

def handler(event, context):
    # chat_room.connection_idから退室者のconnection_idを削除
    print("room_disconnect!!")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from room_disconnect!"
        })
    }
