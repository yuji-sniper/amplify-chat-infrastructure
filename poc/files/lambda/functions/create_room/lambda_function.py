import boto3
import json
import os

def handler(event, context):
    print(event)
    
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": os.environ['FRONTEND_ORIGIN'],
        },
        "body": {
            "message": "Hello from create_room!"
        }
    }
    
    # # リクエストボディからnameを取得
    # body = json.loads(event['body'])
    # name = body['name']
    
    # # DynamoDBのclientを生成
    # dynamodb = boto3.resource('dynamodb')
    # table = dynamodb.Table(os.environ['DYNAMO_CHAT_ROOMS_TABLE'])
