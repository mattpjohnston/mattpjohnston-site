terraform {
  required_version = ">= 1.10.0"

  # bucket is made by hand, it can't hold its own state. versioning is on so
  # a bad state can be rolled back. use_lockfile means no dynamodb lock table.
  backend "s3" {
    bucket       = "mattpjohnston-tfstate-682718097022"
    key          = "environments/prod/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
  profile = var.aws_profile
}
