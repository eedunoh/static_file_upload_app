resource "aws_autoscaling_group" "static_file_app_asg" {
  name = "static_file_app_auto_scaling"

  vpc_zone_identifier = flatten([data.aws_subnets.private_subnets.ids])  # Flattening the list of subnet IDs. This ensures my auto scaling group (ec2) instances are in the private subnets.
  
  # The flatten() function is used to "un-nest" the list of subnet IDs and pass a flat list instead of a list containing another list. ASG configuration expect a list of strings, not a list containing another list.


  desired_capacity   = 1
  max_size           = 3
  min_size           = 1


  launch_template {
      id = aws_launch_template.static_file_app_lt.id    # I attach my launch template here using the launch template id
      version = "$Latest"
  }


  # Attach to Load Balancer (ALB) and turn on health checks
  target_group_arns     = [aws_lb_target_group.alb_tg.arn]    #  target_group_arn of the Application
  health_check_type      = "ELB"             # Ensures ELB performs health checks
  health_check_grace_period = 300            # Wait 5 mins before marking unhealthy. The reason for this is that the image may be large in size and would need more time to initialize. we dont want the ALB marking it unhealthy while its initializing.
}


# Create an autoscaling policy using the 'TargetTrackingScaling' policy type
resource "aws_autoscaling_policy" "cpu_tracking" {
  name = "cpu_tracking"
  autoscaling_group_name = aws_autoscaling_group.static_file_app_asg.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
  predefined_metric_specification {
    predefined_metric_type = "ASGAverageCPUUtilization"  # Uses average CPU utilization across the ASG
  }

    target_value = 30.0  # Scale out when average CPU > 30%
  }
}




output "asg_group_arn" {
    value = aws_autoscaling_group.static_file_app_asg.arn
}