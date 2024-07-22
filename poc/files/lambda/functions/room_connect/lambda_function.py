import boto3
import json
import os

def handler(event, context):
    try:
        # DynamoDBのclientを生成
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # connection_idを取得
        connection_id = event['requestContext']['connectionId']

        # チャットルーム情報を取得
        body = json.loads(event['body'])
        response = table.get_item(
            Key={
                'id': body['room_id'],
            }
        )
        room = response['Item']

        # chat_roomにconnection_idを追加
        room['connection_ids'].append(connection_id)
        table.put_item(
            Item=room
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Connected to the room.",
            }),
        }
    except Exception as e:
        print(e)

        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to connect to the room.",
            }),
        }
