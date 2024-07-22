import boto3
from datetime import datetime
import json
import os

def handler(event, context):
    try:
        # dynamodbのclientを生成
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])

        # リクエストボディからroom_id, messageを取得
        body = json.loads(event['body'])
        room_id = body['room_id']
        message = body['message']
        
        # チャットルーム情報を取得
        response = table.get_item(
            Key={
                'id': room_id,
            }
        )
        room = response['Item']
        
        # メッセージを作成
        message = {
            'message': message,
            'created_at': datetime.now().isoformat(),
        }
        
        # メッセージを追加
        room['messages'].append(message)
        table.put_item(
            Item=room
        )
        
        print(f"Message created.")
        
        # メッセージを送信
        connection_endpoint = f"https://{event['requestContext']['domainName']}/{event['requestContext']['stage']}"
        client = boto3.client('apigatewaymanagementapi', endpoint_url=connection_endpoint)
        connection_ids = room['connection_ids']
        for connection_id in connection_ids:
            client.post_to_connection(
                ConnectionId=connection_id,
                Data=json.dumps(message),
            )
        
        print("Message sent.")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Message sent.",
            }),
        }
    except Exception as e:
        print(e)
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to send message.",
            }),
        }
