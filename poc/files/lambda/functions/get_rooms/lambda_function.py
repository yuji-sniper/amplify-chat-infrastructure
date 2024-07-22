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
        
        # チャットルーム一覧を取得（id, name）
        response = table.scan()
        rooms = response['Items']
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(rooms),
        }
    except Exception as e:
        print(e)
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "message": "Failed to get rooms.",
            }),
        }
    
