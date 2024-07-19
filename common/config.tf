data "aws_caller_identity" "current" {}

terraform {
  required_version = "1.9.2"
  backend "s3" {
    bucket = "amplify-chat.tfstate"
    key = "common.terraform.tfstate"
    region = "ap-northeast-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.58.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "env" = var.env
      "project" = var.project
    }
  }
}
