variable "site" {
  type = string
  description = "The name of the site"
  default = "dist-host"
}

variable "domain" {
  type = string
  description = "The base domain name of the site that all these belong to."
  default = "dist.host"
}

variable "subdomains" {
    type = list
    default = [
      "www",
    ]
}

variable "stage" {
  type = string
  description = "Deployment stage name"
  default = "prod"
}

terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
   region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

