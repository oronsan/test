terraform {
  required_version = ">= 0.13.1"

  backend "s3" {
    bucket = "752738072640-operations"
    key    = "terraform/test/terraform.tfstate"
    region = "us-east-1"
  }
}

