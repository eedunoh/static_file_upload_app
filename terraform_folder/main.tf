
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


terraform {
  backend "s3" {
    bucket = "app-remote-state-bucket-fyi"
    key    = "jenkins/terraform.tfstate"
    region = "eu-north-1"
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}


# In this project, we will provision AWS resources in a VPC with both public and private subnets.
# Since this project uses a CI/CD pipeline, Jenkins will be deployed alongside the VPC and subnets, which will be created first (if it hasn't been created already).
# See deployment files here: https://github.com/eedunoh/jenkins_aws_install_for_static_file_upload

# To proceed with this project, you must first create the VPC, subnets, and install Jenkins using the files in the repository above. 



# Reference the vpc created earlier, Don't create/manage a new one

# Use terraform import if you want Terraform to manage the resource.
# Use data block if you just need to reference an existing resource without managing it.

# AWS is case-sensitive when querying data sources compared to when creating them using aws resources
# Always check how your data is structured especially tags before using them. Name != name  AND  "map-public-ip-on-launch" != "map_public_ip_on_launch"



data "aws_vpc" "main"{
  filter {
    name = "tag:name"
    values = ["static_file_upload_vpc"]      # This is the name of the vpc created earlier
  }
}


# retrieve public subnets id (the two public subnets we created)
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "map-public-ip-on-launch"      # name of the filter we want to use
    values = ["true"]                       # This is the outcome of the filter we expect. Only public subnets auto-assign public IPs
  }
}


# retrieve private subnets id (the two private subnets we created)
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "map-public-ip-on-launch"      # name of the filter we want to use
    values = ["false"]                      # This is the outcome of the filter we expect. Private subnets do not auto-assign public IPs
  }
}


# Outputs

output "main_vpc_id" {
  value = data.aws_vpc.main.id
}


output "public_subnet_ids" {
  value = data.aws_subnets.public_subnets.ids
}


output "private_subnet_ids" {
  value = data.aws_subnets.private_subnets.ids
}