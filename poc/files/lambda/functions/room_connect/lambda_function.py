import boto3
import json
import logging
import os

logging.basicConfig(level=logging.INFO)

def handler(event, context):
    try:
        # DynamoDBのclientを生成
        dynamodb = boto3.resource('dynamodb')
        rooms_table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # connection_idを取得
        connection_id = event['requestContext']['connectionId']

        # チャットルーム情報を取得
        params = event.get('queryStringParameters', {})
        response = rooms_table.get_item(
            Key={
                'id': params['room_id'],
            }
        )
        room = response['Item']

        # chat_roomsにconnection_idを追加
        if 'connection_ids' not in room:
            room['connection_ids'] = []
        room['connection_ids'].append(connection_id)
        rooms_table.put_item(
            Item=room
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Connected to the room.",
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)

        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to connect to the room.",
            }),
        }
