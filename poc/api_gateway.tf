resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch.arn
}


# Websocket API
resource "aws_apigatewayv2_api" "chat-websocket" {
  name                       = "${var.env}-${var.project}-chat-websocket"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

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
  # auto_deploy   = true

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


# REST API
resource "aws_apigatewayv2_api" "chat-rest" {
  name                       = "${var.env}-${var.project}-chat-rest"
  protocol_type              = "HTTP"

  cors_configuration {
    allow_origins = ["https://${aws_amplify_branch.frontend.branch_name}.${aws_amplify_app.frontend.default_domain}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token", "X-Amz-User-Agent"]
  }
}

resource "aws_apigatewayv2_integration" "get-rooms" {
  api_id             = aws_apigatewayv2_api.chat-rest.id
  connection_type    = "INTERNET"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.get_rooms.invoke_arn
}

resource "aws_apigatewayv2_route" "get-rooms" {
  api_id    = aws_apigatewayv2_api.chat-rest.id
  route_key = "GET /rooms"
  target    = "integrations/${aws_apigatewayv2_integration.get-rooms.id}"
}

resource "aws_apigatewayv2_integration" "create-room" {
  api_id             = aws_apigatewayv2_api.chat-rest.id
  connection_type    = "INTERNET"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_room.invoke_arn
}

resource "aws_apigatewayv2_route" "create-room" {
  api_id    = aws_apigatewayv2_api.chat-rest.id
  route_key = "POST /room"
  target    = "integrations/${aws_apigatewayv2_integration.create-room.id}"
}

resource "aws_apigatewayv2_integration" "get-messages" {
  api_id             = aws_apigatewayv2_api.chat-rest.id
  connection_type    = "INTERNET"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.get_messages.invoke_arn
}

resource "aws_apigatewayv2_route" "get-messages" {
  api_id    = aws_apigatewayv2_api.chat-rest.id
  route_key = "GET /messages"
  target    = "integrations/${aws_apigatewayv2_integration.get-messages.id}"
}

resource "aws_apigatewayv2_deployment" "chat-rest" {
  api_id = aws_apigatewayv2_api.chat-rest.id
  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_api.chat-rest))
  }
  depends_on = [
    aws_apigatewayv2_route.get-rooms,
    aws_apigatewayv2_route.create-room,
    aws_apigatewayv2_route.get-messages
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "chat-rest" {
  name          = "${var.env}-${var.project}-chat-rest-poc"
  api_id        = aws_apigatewayv2_api.chat-rest.id
  deployment_id = aws_apigatewayv2_deployment.chat-rest.id

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
    aws_apigatewayv2_deployment.chat-rest
  ]
}
