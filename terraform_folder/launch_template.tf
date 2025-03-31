resource "aws_launch_template" "static_file_app_lt" {
    name = "static_file_app_launch_template"

    image_id = "ami-016038ae9cc8d9f51"    # Amazon Linux 2023 AMI

    instance_initiated_shutdown_behavior = "terminate"

    instance_type = "t3.medium"

    key_name = "webapp1key"   # Modify this field to add your key name here

    network_interfaces {
        associate_public_ip_address = false  # we do not need a public IP since the ec2 will be in the private subnet

        security_groups = [aws_security_group.ec2_sg.id]
    }

    # IAM instance profile (needed for app running on ec2)
    iam_instance_profile {
      name = aws_iam_instance_profile.ec2_instance_profile.name
    }

    credit_specification {
        cpu_credits = "standard"
    }

    user_data = base64encode(file("user_data.sh"))

    tags = {
      Name = "Static-File-Upload-App-Server"
    }
}


output "launch_template_id" {
  value = aws_launch_template.static_file_app_lt.id
}
