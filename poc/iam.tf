# API Gateway
data "aws_iam_policy_document" "apigateway_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigateway_cloudwatch" {
  name               = "${var.env}-${var.project}-apigateway"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json
}

data "aws_iam_policy_document" "apigateway_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "apigateway_cloudwatch" {
  name   = "${var.env}-${var.project}-apigateway-cloudwatch"
  policy = data.aws_iam_policy_document.apigateway_cloudwatch.json
}

resource "aws_iam_policy_attachment" "apigateway_cloudwatch" {
  name       = "${var.env}-${var.project}-apigateway-cloudwatch"
  policy_arn = aws_iam_policy.apigateway_cloudwatch.arn
  roles = [
    aws_iam_role.apigateway_cloudwatch.name,
  ]
}


# Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_get_rooms" {
  name               = "${var.env}-${var.project}-lambda-get-rooms"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_create_room" {
  name               = "${var.env}-${var.project}-lambda-create-room"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_delete_connection" {
  name               = "${var.env}-${var.project}-lambda-delete-connection"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_room_connect" {
  name               = "${var.env}-${var.project}-lambda-room-connect"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_room_disconnect" {
  name               = "${var.env}-${var.project}-lambda-room-disconnect"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_send_message" {
  name               = "${var.env}-${var.project}-lambda-send-message"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_send_connection_id" {
  name               = "${var.env}-${var.project}-lambda-send-connection-id"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.env}-${var.project}-*:*",
    ]
  }
}

resource "aws_iam_policy" "lambda_log" {
  name   = "${var.env}-${var.project}-lambda-log"
  policy = data.aws_iam_policy_document.lambda_log.json
}

resource "aws_iam_policy_attachment" "lambda_log" {
  name       = "${var.env}-${var.project}-lambda-log"
  policy_arn = aws_iam_policy.lambda_log.arn
  roles = [
    aws_iam_role.lambda_get_rooms.name,
    aws_iam_role.lambda_create_room.name,
    aws_iam_role.lambda_delete_connection.name,
    aws_iam_role.lambda_room_connect.name,
    aws_iam_role.lambda_room_disconnect.name,
    aws_iam_role.lambda_send_message.name,
    aws_iam_role.lambda_send_connection_id.name,
  ]
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.env}-${var.project}-*",
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name   = "${var.env}-${var.project}-lambda-dynamodb"
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_iam_policy_attachment" "lambda_dynamodb" {
  name       = "${var.env}-${var.project}-lambda-dynamodb"
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
  roles = [
    aws_iam_role.lambda_get_rooms.name,
    aws_iam_role.lambda_create_room.name,
    aws_iam_role.lambda_delete_connection.name,
    aws_iam_role.lambda_room_connect.name,
    aws_iam_role.lambda_room_disconnect.name,
    aws_iam_role.lambda_send_message.name,
    aws_iam_role.lambda_send_connection_id.name,
  ]
}

data "aws_iam_policy_document" "lambda_websocket_api" {
  statement {
    effect = "Allow"
    actions = [
      "execute-api:ManageConnections",
    ]
    resources = [
      "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.chat-websocket.id}/${aws_apigatewayv2_stage.chat-websocket.name}/POST/@connections/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_websocket_api" {
  name   = "${var.env}-${var.project}-lambda-websocket-api"
  policy = data.aws_iam_policy_document.lambda_websocket_api.json
}

resource "aws_iam_policy_attachment" "lambda_websocket_api" {
  name       = "${var.env}-${var.project}-lambda-websocket-api"
  policy_arn = aws_iam_policy.lambda_websocket_api.arn
  roles = [
    aws_iam_role.lambda_send_message.name,
    aws_iam_role.lambda_send_connection_id.name,
  ]
}
