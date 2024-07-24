import boto3
import json
import logging
import os

logging.basicConfig(level=logging.INFO)

def handler(event, context):
    try:
        # # DynamoDBのclientを生成
        # dynamodb = boto3.resource('dynamodb')
        # rooms_table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # # connection_idを取得
        # connection_id = event['requestContext']['connectionId']
        
        # # チャットルーム情報を取得
        # print(event)
        # body = json.loads(event['body'])
        # room_id = body['data']['room_id']
        # response = rooms_table.get_item(
        #     Key={
        #         'id': room_id,
        #     }
        # )
        # room = response['Item']

        # # chat_roomsからconnection_idを削除
        # room['connection_ids'].remove(connection_id)
        # rooms_table.put_item(
        #     Item=room
        # )

        # print(f"Disconnected from the room.")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Disconnected from the room.",
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)

        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to disconnect from the room.",
            }),
        }
