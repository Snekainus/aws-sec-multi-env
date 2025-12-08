terraform {
  backend "s3" {
    bucket         = "tfstate-web-aws-multi-env"
    dynamodb_table = "terraform-locks"
    region         = "us-east-1"
    encrypt        = true
    key            = "placeholder/terraform.tfstate"
  }
}
