terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
  # region = "eu-central-1"
}

# Load some json variables from a file (https://discuss.hashicorp.com/t/how-to-work-with-json/2345)
locals {
  json_vars = jsondecode(file("${path.module}/variables.json"))
}
