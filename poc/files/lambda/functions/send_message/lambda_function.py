import json

def handler(event, context):
    # chat_room.messagesに新たなメッセージを追加
    # 入室者（chat_room.connection_ids）にWebSocket APIで新たなメッセージを送信
    print(json.loads(event["body"]))
    
    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from send_message!"
        }
    }
