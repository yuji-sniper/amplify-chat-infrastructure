import boto3
from datetime import datetime
import json
import os

def handler(event, context):
    # chat_room.messagesに新たなメッセージを追加
    print(json.loads(event["body"]))
    
    # 現在時刻を取得して文字列化
    now = datetime.now()
    nowStr = now.strftime('%Y-%m-%d %H:%M:%S')
    
    # 入室者（chat_room.connection_ids）にWebSocket APIで新たなメッセージを送信
    connection_endpoint = f"https://{event['requestContext']['domainName']}/{event['requestContext']['stage']}"
    client = boto3.client('apigatewaymanagementapi', endpoint_url=connection_endpoint)
    response = client.post_to_connection(
        ConnectionId=event["requestContext"]["connectionId"],
        Data=json.dumps({
            "message": f"Hello from send_message! {nowStr}"
        })
    )
    
    print(response)
    
    return {"statusCode": 200}
