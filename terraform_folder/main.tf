
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# terraform {
#   backend "s3" {
#     bucket = "app-remote-state-bucket-fyi"
#     key    = "jenkins/terraform.tfstate"
#     region = "eu-north-1"
#   }
# }


# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}


# We create a new VPC
resource  "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "static_file_upload"
  }
}


# We create two public subnets for two availability zones in our region (within the same VPC)

resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}



resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}



# We create two private subnets for two availability zones in our region (within the same VPC)

resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    name = "private_subnet_1"
  }
}



resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    name = "private_subnet_2"
  }
}





# Create an internet gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    name = "new_internet_gateway"
  }
}





# we need two NAT gateways to be palced in the two availability zones (public subnets). Each NAT gateway should have an elastic IP attched to it


# NAT gateway1 and its elastic IP
resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw1" {
  subnet_id = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip1.id

  tags = {
    name = "private_nat_gw1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}



# NAT gateway2 and its elastic IP
resource "aws_eip" "nat_eip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw2" {
  subnet_id = aws_subnet.public_subnet_2.id
  allocation_id = aws_eip.nat_eip2.id

  tags = {
    name = "private_nat_gw2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}



# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }

  tags = {
    name = "public_route_table"
  }
}





# Create two route tables for the private subnet and add the one nat gateway to each of them
resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id
    }

  tags = {
    name = "private_route_table1"
  }

}



resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id
    }

  tags = {
    name = "private_route_table2"
  }

}




# Associate the public route table to the 2 public subnets in the two availability zones

resource "aws_route_table_association" "public_assoc1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_route_table_association" "public_assoc2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}



# Associate the two private route tables to the 2 private subnets in the two availability zones

resource "aws_route_table_association" "private_assoc1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table1.id
}


resource "aws_route_table_association" "private_assoc2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table2.id
}




# Outputs

output "main_vpc_id" {
  value = aws_vpc.main.id
}


output "main_public_subnets" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}


output "main_private_subnets" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}