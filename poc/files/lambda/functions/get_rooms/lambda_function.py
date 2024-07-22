import json
import os

def handler(event, context):
    # チャットルーム一覧を取得
    table = os.environ['DYNAMO_CHAT_ROOMS_TABLE']
    
    print(f"table: {table}")
    
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": os.environ['FRONTEND_ORIGIN'],
        },
        "body": json.dumps({
            "message": "Hello from get_rooms!",
        }),
    }
