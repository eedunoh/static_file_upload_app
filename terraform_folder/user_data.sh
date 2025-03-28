#!/bin/bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Add ec2-user to Docker group
sudo usermod -aG docker ec2-user

# Run the Docker container
sudo docker run -d -p 80:80 --name blog_app_container jackedu/blog_app_repo:latest
# sudo docker run -d -p 80:80 --name static_file_upload_app_container jackedu/static_file_upload_app_repo:latest

# Confirm Docker version
docker --version
