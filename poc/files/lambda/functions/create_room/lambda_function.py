import boto3
import json
import logging
import os
import uuid

logging.basicConfig(level=logging.INFO)

def handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": os.environ['FRONTEND_ORIGIN'],
    }
    
    try:
        # リクエストボディからnameを取得
        body = json.loads(event['body'])
        name = body['name']
        
        # DynamoDBのclientを生成
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])
        
        # ユニークなIDの部屋を作成
        room_id = str(uuid.uuid4())
        table.put_item(
            Item={
                'id': room_id,
                'name': name,
            }
        )
        
        print(f"Room created: {room_id}")
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "id": room_id,
                "name": name,
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Failed to create room.",
            }),
        }
