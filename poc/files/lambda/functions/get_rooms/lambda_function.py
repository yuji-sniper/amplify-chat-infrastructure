def lambda_handler(event, context):
    # チャットルーム一覧を取得
    print(event)
    
    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from get_rooms!"
        }
    }
