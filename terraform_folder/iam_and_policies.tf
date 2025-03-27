
# this role grants permissions to lambda to carryout actions on s3
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_role_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}



# Create a lambda:InvokeFunction. This is important because S3 needs explicit permission to invoke Lambda.
# When using the AWS Management Console, AWS automatically adds the required Lambda:InvokeFunction permission behind the scenes. In terraform, we need to explicitly configure it.
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.static_upload_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_normal_objects.arn
}



# Policy to be attached to the lambda role above.
# Lambda can only LIST and PUT objects in s3_sensitive_object_bucket. It can GET, LIST, GETObjectTagging, COPY and DELETE objects in s3_normal_object_bucket

resource "aws_iam_policy" "s3_access" {
  name        = "s3_access"
  description = "Allows Lambda to access s3 buckets - least privilege"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:ListBucket",
        "s3:GetObjectTagging",
        "s3:CopyObject",
        "s3:DeleteObject"
				],
			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
		},

      {
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:ListBucket",
				],
			"Resource": [
				"${aws_s3_bucket.s3_sensitive_objects.arn}/*"
			]
		}
    ]
  })
}


# attach s3_access policy to the lambda iam role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.s3_access.arn
}







# This role grants permissions to the application in ec2 to access AWS services like SSM Parameter Store and s3
resource "aws_iam_role" "ec2_instance_role" {
  name = "EC2InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}



# Policy to be attached to the ec2 role above. 
# The application only have acces to get Cognito properties from SSM and normal s3 bucket

resource "aws_iam_policy" "ssm_read_access_and_s3_access" {
  name        = "ssm_read_access_and_s3_access"
  description = "Allows EC2 instance to read SSM parameters and access s3_normal_object bucket"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
      Effect   = "Allow",
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParameterHistory"],
      Resource = "*"
    },

      {
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:GetObject",
				"s3:ListBucket",
				],
			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
		}
    ]
  })
}


# attach ssm_read_access_and_s3_access policy to the ec2 instance role
resource "aws_iam_role_policy_attachment" "ec2_instance_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ssm_read_access_and_s3_access.arn
}



# Create an iam instance profile for the ec2 instance role. This will be attched to the instance in the launch template.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_instance_role.name
}





output "lambda_iam_role_arn" {
  value = aws_iam_role.iam_for_lambda.arn
}


output "iam_instance_profile_name" {
    value = aws_iam_instance_profile.ec2_instance_profile.name
}


output "ec2_instance_role_arn" {
  value = aws_iam_role.ec2_instance_role.arn
}