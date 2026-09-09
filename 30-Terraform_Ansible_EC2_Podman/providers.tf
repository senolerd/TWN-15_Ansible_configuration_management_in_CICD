
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    ansible = {
      source = "ansible/ansible"
      version = "~> 1.4.0"

    }
  }
#   backend "s3" {
#     # Bucket, Key and Region should be set at at init, like;
#     # "-backend-config="bucket=...", "-backend-config="key=...", -backend-config="region=..."
#  }
}

provider "aws" {
  region = "us-east-1"
}
