import boto3
import json
import logging

logging.basicConfig(level=logging.INFO)

def handler(event, context):
    try:
        # connection_idを取得
        connection_id = event['requestContext']['connectionId']

        # connection_idを送信
        connection_endpoint = f"https://{event['requestContext']['domainName']}/{event['requestContext']['stage']}"
        client = boto3.client('apigatewaymanagementapi', endpoint_url=connection_endpoint)
        client.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                'type': 'connection',
                'connection_id': connection_id,
            }),
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Action processed.",
            }),
        }
    except Exception as e:
        logging.error("Error", exc_info=True)

        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to process action.",
            }),
        }
