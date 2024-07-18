data "aws_secretsmanager_secret" "github" {
  name = "github"
}

data "aws_secretsmanager_secret_version" "github" {
  secret_id = data.aws_secretsmanager_secret.github.id
}

resource "aws_amplify_app" "frontend" {
  name     = "${var.env}-${var.project}-frontend"
  repository = var.github_repository
  access_token = jsondecode(data.aws_secretsmanager_secret_version.github.secret_string)["personal_access_token"]
  platform = "WEB_COMPUTE"

  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404"
  }

  enable_branch_auto_deletion = true
}

resource "aws_amplify_branch" "frontend" {
  app_id = aws_amplify_app.frontend.id
  branch_name = "master"
  enable_auto_build = true
  stage = "PRODUCTION"
}
