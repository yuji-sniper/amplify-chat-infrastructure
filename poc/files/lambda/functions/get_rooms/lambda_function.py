import json
import os

def handler(event, context):
    # チャットルーム一覧を取得
    table = os.environ['DYNAMO_CHAT_ROOMS_TABLE']
    
    print(f"table: {table}")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from get_rooms!",
        }),
    }
