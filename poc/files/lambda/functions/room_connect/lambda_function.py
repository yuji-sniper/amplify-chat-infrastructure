def handler(event, context):
    # chat_room.connection_idsに新たな入室者のconnection_idを追加
    print(event)
    
    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from room_connect!"
        }
    }
