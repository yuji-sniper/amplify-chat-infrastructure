import boto3
import json
import os

def handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": os.environ['FRONTEND_ORIGIN'],
    }
    
    try:
        # DynamoDBのclientを生成
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])
        
        # チャットルーム情報を取得
        body = json.loads(event['body'])
        response = table.get_item(
            Key={
                'id': body['room_id'],
            }
        )
        room = response['Item']
        
        # チャットメッセージを取得
        messages = room['messages']
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(messages),
        }
    except Exception as e:
        print(e)
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Failed to get messages.",
            }),
        }
