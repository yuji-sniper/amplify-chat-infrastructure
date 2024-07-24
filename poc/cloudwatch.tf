# Amplify
resource "aws_cloudwatch_log_group" "amplify" {
  name              = "/aws/amplify/${var.env}-${var.project}"
  retention_in_days = 30
}


# API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_chat_websocket" {
  name              = "/aws/api-gateway/${var.env}-${var.project}-chat-websocket"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "api_gateway_chat_rest" {
  name              = "/aws/api-gateway/${var.env}-${var.project}-chat-rest"
  retention_in_days = 30
}


# Lambda
locals {
  lambda_functions = toset([
    aws_lambda_function.create_room.function_name,
    aws_lambda_function.get_rooms.function_name,
    aws_lambda_function.delete_connection.function_name,
    aws_lambda_function.room_connect.function_name,
    aws_lambda_function.room_disconnect.function_name,
    aws_lambda_function.send_message.function_name,
    aws_lambda_function.send_connection_id.function_name,
  ])
}

resource "aws_cloudwatch_log_group" "lambda_function" {
  for_each          = local.lambda_functions
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 30
}
