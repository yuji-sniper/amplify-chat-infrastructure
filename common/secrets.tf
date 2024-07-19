resource "aws_secretsmanager_secret" "github-credentials" {
  name = "github-credentials"
}

resource "aws_secretsmanager_secret_version" "github-credentials" {
  secret_id = aws_secretsmanager_secret.github-credentials.id
  secret_string = jsonencode({
    personal_access_token = "PleaseChange!"
  })
}
