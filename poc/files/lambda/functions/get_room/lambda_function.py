import boto3
import json
import logging
import os

logging.basicConfig(level=logging.INFO)

def handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": os.environ['FRONTEND_ORIGIN'],
    }
    
    try:
        # DynamoDBのclientを生成
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])
        
        # クエリパラメータのroom_idを取得
        room_id = event['queryStringParameters']['room_id']

        # チャットルームを取得（id, name）
        response = table.get_item(
            Key={
                'id': room_id,
            }
        )
        if 'Item' not in response:
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({
                    "message": "Room not found.",
                }),
            }
        room = response['Item']

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "room": room,
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Failed to get room.",
            }),
        }
