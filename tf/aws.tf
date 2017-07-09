provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "remote_state" {
    backend = "s3"
    config {
      bucket = "some-bucket"
      key = "pipeline/terraform.tfstate"
      region = "us-east-1"
    }
}