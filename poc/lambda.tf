############################################
# レイヤー
############################################
locals {
  python_packages_requirements_path = "${path.module}/files/lambda/layers/python_packages/requirements.txt"
  python_packages_output_path       = "${path.module}/outputs/lambda/layers/outputs/python_packages/output.zip"
  python_packages_venv_dir          = "${path.module}/outputs/lambda/venv"
  python_packages_source_dir        = "${path.module}/outputs/lambda/layers/sources/python_packages"
}

resource "null_resource" "prepare_python_packages" {
  triggers = {
    "requirements_diff" = filebase64(local.python_packages_requirements_path)
  }

  provisioner "local-exec" {
    command = <<-EOF
      rm -rf ${local.python_packages_source_dir}/python &&
      mkdir -p ${local.python_packages_source_dir}/python &&
      docker pull python:3.12-slim &&
      docker run --rm -v $(pwd)/${local.python_packages_requirements_path}:/app/requirements.txt \
      -v $(pwd)/${local.python_packages_source_dir}/python:/app/python \
      python:3.12-slim /bin/sh -c "
        pip install -r /app/requirements.txt -t /app/python
      "
    EOF

    on_failure = fail
  }
}

data "archive_file" "python_packages_layer" {
  type        = "zip"
  source_dir  = local.python_packages_source_dir
  output_path = local.python_packages_output_path

  depends_on = [
    null_resource.prepare_python_packages
  ]
}

resource "aws_lambda_layer_version" "python_packages" {
  layer_name          = "${var.env}-${var.project}-python-packages"
  s3_bucket           = aws_s3_bucket.lambda_layers.id
  s3_key              = aws_s3_object.python_packages_layer.key
  source_code_hash    = data.archive_file.python_packages_layer.output_md5
  compatible_runtimes = ["python3.12"]
}

resource "aws_s3_object" "python_packages_layer" {
  bucket = aws_s3_bucket.lambda_layers.id
  key    = "python_packages_layer.zip"
  source = data.archive_file.python_packages_layer.output_path
  etag   = data.archive_file.python_packages_layer.output_md5
}


############################################
# Lambda関数
############################################

# チャットルーム取得関数（REST API）
data "archive_file" "get_rooms" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/get_rooms"
  output_path = "${path.module}/outputs/lambda/functions/get_rooms.zip"
}

resource "aws_lambda_function" "get_rooms" {
  function_name    = "${var.env}-${var.project}-get-rooms"
  role             = aws_iam_role.lambda_get_rooms.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.get_rooms.key
  source_code_hash = data.archive_file.get_rooms.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      FRONTEND_ORIGIN = local.frontend_origin,
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "get_rooms" {
  statement_id  = "AllowExecutionFromAPIGatewayGetRooms"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_rooms.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.chat-rest.id}/*/${aws_api_gateway_method.get-rooms.http_method}${aws_api_gateway_resource.get-rooms.path}"
}

resource "aws_s3_object" "get_rooms" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "get_rooms.zip"
  source = data.archive_file.get_rooms.output_path
  etag   = data.archive_file.get_rooms.output_base64sha256
}

# チャットルーム作成関数（REST API）
data "archive_file" "create_room" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/create_room"
  output_path = "${path.module}/outputs/lambda/functions/create_room.zip"
}

resource "aws_lambda_function" "create_room" {
  function_name    = "${var.env}-${var.project}-create-room"
  role             = aws_iam_role.lambda_create_room.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.create_room.key
  source_code_hash = data.archive_file.create_room.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      FRONTEND_ORIGIN = local.frontend_origin,
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "create_room" {
  statement_id  = "AllowExecutionFromAPIGatewayCreateRoom"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_room.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.chat-rest.id}/*/${aws_api_gateway_method.create-room.http_method}${aws_api_gateway_resource.create-room.path}"
}

resource "aws_s3_object" "create_room" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "create_room.zip"
  source = data.archive_file.create_room.output_path
  etag   = data.archive_file.create_room.output_base64sha256
}

# メッセージ一覧取得関数（REST API）
data "archive_file" "get_messages" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/get_messages"
  output_path = "${path.module}/outputs/lambda/functions/get_messages.zip"
}

resource "aws_lambda_function" "get_messages" {
  function_name    = "${var.env}-${var.project}-get-messages"
  role             = aws_iam_role.lambda_get_messages.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.get_messages.key
  source_code_hash = data.archive_file.get_messages.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      FRONTEND_ORIGIN = local.frontend_origin,
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "get_messages" {
  statement_id  = "AllowExecutionFromAPIGatewayGetMessages"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_messages.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.chat-rest.id}/*/${aws_api_gateway_method.get-messages.http_method}${aws_api_gateway_resource.get-messages.path}"
}

resource "aws_s3_object" "get_messages" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "get_messages.zip"
  source = data.archive_file.get_messages.output_path
  etag   = data.archive_file.get_messages.output_base64sha256
}

# メッセージ送信関数（WebSocket API）
data "archive_file" "send_message" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/send_message"
  output_path = "${path.module}/outputs/lambda/functions/send_message.zip"
}

resource "aws_lambda_function" "send_message" {
  function_name    = "${var.env}-${var.project}-send-message"
  role             = aws_iam_role.lambda_send_message.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.send_message.key
  source_code_hash = data.archive_file.send_message.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "send_message" {
  statement_id  = "AllowExecutionFromAPIGatewaySendMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_message.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.chat-websocket.id}/*/${aws_apigatewayv2_route.send-message.route_key}"
}

resource "aws_s3_object" "send_message" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "send_message.zip"
  source = data.archive_file.send_message.output_path
  etag   = data.archive_file.send_message.output_base64sha256
}

# 部屋コネクト（WebSocket API）
data "archive_file" "room_connect" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/room_connect"
  output_path = "${path.module}/outputs/lambda/functions/room_connect.zip"
}

resource "aws_lambda_function" "room_connect" {
  function_name    = "${var.env}-${var.project}-room-connect"
  role             = aws_iam_role.lambda_room_connect.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.room_connect.key
  source_code_hash = data.archive_file.room_connect.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "room_connect" {
  statement_id  = "AllowExecutionFromAPIGatewayRoomConnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.room_connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.chat-websocket.id}/*/${aws_apigatewayv2_route.room-connect.route_key}"
}

resource "aws_s3_object" "room_connect" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "room_connect.zip"
  source = data.archive_file.room_connect.output_path
  etag   = data.archive_file.room_connect.output_base64sha256
}

# 部屋ディスコネクト（WebSocket API）
data "archive_file" "room_disconnect" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda/functions/room_disconnect"
  output_path = "${path.module}/outputs/lambda/functions/room_disconnect.zip"
}

resource "aws_lambda_function" "room_disconnect" {
  function_name    = "${var.env}-${var.project}-room-disconnect"
  role             = aws_iam_role.lambda_room_disconnect.arn
  handler          = "lambda_function.handler"
  s3_bucket        = aws_s3_bucket.lambda_functions.id
  s3_key           = aws_s3_object.room_disconnect.key
  source_code_hash = data.archive_file.room_disconnect.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  layers = [
    aws_lambda_layer_version.python_packages.arn
  ]

  environment {
    variables = {
      DYNAMO_CHAT_ROOMS_TABLE = aws_dynamodb_table.chat_rooms.name
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_lambda_permission" "room_disconnect" {
  statement_id  = "AllowExecutionFromAPIGatewayRoomDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.room_disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.chat-websocket.id}/*/${aws_apigatewayv2_route.room-disconnect.route_key}"
}

resource "aws_s3_object" "room_disconnect" {
  bucket = aws_s3_bucket.lambda_functions.id
  key    = "room_disconnect.zip"
  source = data.archive_file.room_disconnect.output_path
  etag   = data.archive_file.room_disconnect.output_base64sha256
}
