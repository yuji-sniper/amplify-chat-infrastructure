resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch.arn
}


############################################
# Websocket API
############################################
resource "aws_apigatewayv2_api" "chat-websocket" {
  name                       = "${var.env}-${var.project}-chat-websocket"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# コネクト
resource "aws_apigatewayv2_integration" "room-connect" {
  api_id             = aws_apigatewayv2_api.chat-websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.room_connect.invoke_arn
}

resource "aws_apigatewayv2_route" "room-connect" {
  api_id    = aws_apigatewayv2_api.chat-websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.room-connect.id}"
}

# ディスコネクト
resource "aws_apigatewayv2_integration" "room-disconnect" {
  api_id             = aws_apigatewayv2_api.chat-websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.room_disconnect.invoke_arn
}

resource "aws_apigatewayv2_route" "room-disconnect" {
  api_id    = aws_apigatewayv2_api.chat-websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.room-disconnect.id}"
}

# メッセージ送信
resource "aws_apigatewayv2_integration" "send-message" {
  api_id             = aws_apigatewayv2_api.chat-websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.send_message.invoke_arn
}

resource "aws_apigatewayv2_route" "send-message" {
  api_id    = aws_apigatewayv2_api.chat-websocket.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.send-message.id}"
}

resource "aws_apigatewayv2_deployment" "chat-websocket" {
  api_id = aws_apigatewayv2_api.chat-websocket.id
  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_api.chat-websocket))
  }
  depends_on = [
    aws_apigatewayv2_route.room-connect,
    aws_apigatewayv2_route.room-disconnect,
    aws_apigatewayv2_route.send-message
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "chat-websocket" {
  name          = "${var.env}-${var.project}-chat-websocket-poc"
  api_id        = aws_apigatewayv2_api.chat-websocket.id
  deployment_id = aws_apigatewayv2_deployment.chat-websocket.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_chat_websocket.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      requestTime    = "$context.requestTime",
      routeKey       = "$context.routeKey",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [
    aws_apigatewayv2_deployment.chat-websocket
  ]
}


############################################
# REST API
############################################
locals {
  frontend_origin = "https://${aws_amplify_branch.frontend.branch_name}.${aws_amplify_app.frontend.default_domain}"
}

resource "aws_api_gateway_rest_api" "chat-rest" {
  name = "${var.env}-${var.project}-chat-rest"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 部屋一覧取得
resource "aws_api_gateway_resource" "get-rooms" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  parent_id   = aws_api_gateway_rest_api.chat-rest.root_resource_id
  path_part   = "rooms"
}

resource "aws_api_gateway_method" "get-rooms" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-rooms" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_method.get-rooms.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_rooms.invoke_arn
  connection_type = "INTERNET"
}

resource "aws_api_gateway_integration_response" "get-rooms" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_integration.get-rooms.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  depends_on = [
    aws_api_gateway_integration.get-rooms
  ]
}

resource "aws_api_gateway_method_response" "get-rooms" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_method.get-rooms.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "get-rooms-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-rooms-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_method.get-rooms-options.http_method
  type        = "MOCK"  // バックエンド(Lambda)にリクエストを送信せずにテンプレートレスポンスを返す

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "get-rooms-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_integration.get-rooms-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.get-rooms-options
  ]
}

resource "aws_api_gateway_method_response" "get-rooms-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-rooms.id
  http_method = aws_api_gateway_method.get-rooms-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# 部屋作成
resource "aws_api_gateway_resource" "create-room" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  parent_id   = aws_api_gateway_rest_api.chat-rest.root_resource_id
  path_part   = "room"
}

resource "aws_api_gateway_method" "create-room" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create-room" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_method.create-room.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.create_room.invoke_arn
  connection_type = "INTERNET"
}

resource "aws_api_gateway_integration_response" "create-room" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_integration.create-room.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  depends_on = [
    aws_api_gateway_integration.create-room
  ]
}

resource "aws_api_gateway_method_response" "create-room" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_method.create-room.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "create-room-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create-room-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_method.create-room-options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "create-room-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_integration.create-room-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.create-room-options
  ]
}

resource "aws_api_gateway_method_response" "create-room-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.create-room.id
  http_method = aws_api_gateway_method.create-room-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# メッセージ一覧取得
resource "aws_api_gateway_resource" "get-messages" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  parent_id   = aws_api_gateway_rest_api.chat-rest.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_method" "get-messages" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-messages" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_method.get-messages.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_messages.invoke_arn
  connection_type = "INTERNET"
}

resource "aws_api_gateway_integration_response" "get-messages" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_integration.get-messages.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  depends_on = [
    aws_api_gateway_integration.get-messages
  ]
}

resource "aws_api_gateway_method_response" "get-messages" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_method.get-messages.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "get-messages-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-messages-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_method.get-messages-options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "get-messages-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_integration.get-messages-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.get-messages-options
  ]
}

resource "aws_api_gateway_method_response" "get-messages-options" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  resource_id = aws_api_gateway_resource.get-messages.id
  http_method = aws_api_gateway_method.get-messages-options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# エラーレスポンス
resource "aws_api_gateway_gateway_response" "chat-rest-4xx" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  response_type = "DEFAULT_4XX"
  status_code = "400"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'"
  }

  response_templates = {
    "application/json" = "{ \"message\": \"$context.error.messageString\" }"
  }
}

resource "aws_api_gateway_gateway_response" "chat-rest-5xx" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  response_type = "DEFAULT_5XX"
  status_code = "500"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${local.frontend_origin}'"
  }

  response_templates = {
    "application/json" = "{ \"message\": \"$context.error.messageString\" }"
  }
}

# デプロイ
resource "aws_api_gateway_deployment" "chat-rest" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.chat-rest))
  }

  depends_on = [
    aws_api_gateway_integration.get-rooms,
    aws_api_gateway_integration.create-room,
    aws_api_gateway_integration.get-messages
  ]
}

resource "aws_api_gateway_stage" "chat-rest" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  stage_name  = "poc"
  deployment_id = aws_api_gateway_deployment.chat-rest.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_chat_rest.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      requestTime    = "$context.requestTime",
      routeKey       = "$context.routeKey",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [
    aws_api_gateway_deployment.chat-rest
  ]
}

data "aws_iam_policy_document" "chat-rest-apigateway-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "execute-api:Invoke"
    ]
    resources = [
      "${aws_api_gateway_rest_api.chat-rest.execution_arn}/*"
    ]
  }
}

resource "aws_api_gateway_rest_api_policy" "chat-rest" {
  rest_api_id = aws_api_gateway_rest_api.chat-rest.id
  policy     = data.aws_iam_policy_document.chat-rest-apigateway-policy.json
}