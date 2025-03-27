
# Since the app is in the private subnet, it needs to access S3 without using a NAT Gateway or Internet Gateway.

# Normally, instances in a private subnet cannot access the internet (including AWS services like S3) unless you:

# Use a NAT Gateway (costly)

# Use a VPC Endpoint (cheaper & recommended)

# In this project I will use VPN Endpoint as an alternative to NAT Gateway. A VPC Endpoint for S3 allows the private subnet direct access to S3 over AWS's internal network, eliminating the need for public internet access.


variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"  # Change this if needed
}

resource "aws_vpc_endpoint" "private_subnet_vpc_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"  # Use the region variable here
  vpc_endpoint_type = "Gateway"  # S3 requires a Gateway endpoint

  route_table_ids = [
    aws_route_table.private_route_table.id,  # Attach to the private subnet's route table
  ]
}


output "private_subnet_s3_access_id" {
    value = aws_vpc_endpoint.private_subnet_vpc_endpoint.id
}