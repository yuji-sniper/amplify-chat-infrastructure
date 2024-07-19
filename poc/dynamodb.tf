resource "aws_dynamodb_table" "chat_rooms" {
  name           = "${var.env}-${var.project}-chat-rooms"
  billing_mode   = "PROVISIONED"
  hash_key       = "id"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "id"
    type = "S"
  }
}
