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
        rooms_table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # リクエストボディを取得
        body = json.loads(event['body'])
        room_id = body['room_id']
        connection_id = body['connection_id']
        if connection_id is None:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({
                    "message": "connection_id is not specified.",
                }),
            }

        # チャットルーム情報を取得
        response = rooms_table.get_item(
            Key={
                'id': room_id,
            }
        )
        room = response['Item']

        # chat_roomsからconnection_idを削除
        room['connection_ids'].remove(connection_id)
        rooms_table.put_item(
            Item=room
        )

        print("Disconnected from the room.")

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": "Disconnected from the room.",
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)

        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Failed to disconnect from the room.",
            }),
        }
