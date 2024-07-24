import boto3
from datetime import datetime
import json
import logging
import os
import uuid

def handler(event, context):
    try:
        # dynamodbのclientを生成
        dynamodb = boto3.resource('dynamodb')
        rooms_table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # リクエストボディからroom_id, messageを取得
        body = json.loads(event['body'])
        room_id = body['data']['room_id']
        text = body['data']['text']
        
        # チャットルーム情報を取得
        response = rooms_table.get_item(
            Key={
                'id': room_id,
            }
        )
        room = response['Item']
        
        # メッセージを作成
        message = {
            'id': str(uuid.uuid4()),
            'text': text,
            'created_at': datetime.now().isoformat(),
        }
        
        # メッセージを送信
        connection_endpoint = f"https://{event['requestContext']['domainName']}/{event['requestContext']['stage']}"
        print(f"Connection endpoint: {connection_endpoint}")
        client = boto3.client('apigatewaymanagementapi', endpoint_url=connection_endpoint)
        connection_ids = room['connection_ids']
        print(f"Connection IDs: {connection_ids}")
        valid_connection_ids = []
        for connection_id in connection_ids:
            try:
                client.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps({
                        'type': 'message',
                        'message': message,
                    }),
                )
                valid_connection_ids.append(connection_id)
                print(f"Message sent to connection ID {connection_id}.")
            except client.exceptions.GoneException:
                print(f"Connection ID {connection_id} is gone.")
        
        # 有効なconnection_idのみを保持
        if len(valid_connection_ids) < len(connection_ids):
            room['connection_ids'] = valid_connection_ids
            rooms_table.put_item(
                Item=room
            )
            print(f"Removed invalid connection IDs.")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Message sent.",
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to send message.",
            }),
        }
