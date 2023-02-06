# Provider : interact with remote systems
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "4.28.0"
            configuration_aliases = [ aws.src, aws.dst ]
        }
    }
}

provider "aws" {
    alias = "apn2"
    region  = "ap-northeast-2"
    access_key = ""
    secret_key = ""
}

provider "aws" {
    alias = "aps1"
    region  = "ap-south-1"
    shared_credentials_files = []
}

provider "google" {
    alias       = "usw1"
    credentials = "${file("account.json")}"
    project     = "my-project-id"
    region      = "us-west1"
    zone        = "us-west1-a"
}

provider "google" {
    alias       = "usw2"
    credentials = "${file("account.json")}"
    project     = "my-project-id"
    region      = "us-west2"
    zone        = "us-west2-a"
}
#################################################


locals {
    service_name = "forum"
    owner = "Community Team"
}

locals {
    common_tags = {
        Service = local.service_name
        Owner = local.owner
    }
}

module "network" {
    provider = aws.aps1
    source = "./modules/vpc"
}

/*
module "server" {
    source = "./modules/ec2"
}


module "storage" {
    source = "./modules/s3"
}


module "auth" {
    source = "./modules/auth"
}


module "container" {
    source = "./modules/eks"
}

*/