
# Create the normal bucket
resource "aws_s3_bucket" "s3_normal_objects" {
  bucket = "s3-normal-objects-bucket"
}


# Add a policy to the normal object bucket. This will allow lambda to carry out only GET, LIST and DELETE actions on the bucket
resource "aws_s3_bucket_policy" "s3_normal_objects_bucket_policy" {
  bucket = aws_s3_bucket.s3_normal_objects.id

  policy = jsonencode(
    {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal" = "${aws_lambda_function.static_upload_lambda_function.arn}",
			"Action": [
				"s3:GetObject",
				"s3:ListBucket",
				"s3:DeleteObject"
			],
			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}",
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
		},

		{
			"Effect": "Allow",
			"Principal" = {
                AWS = "${aws_iam_role.ec2_instance_role.arn}"   # Allow only EC2 IAM role. We cant use ec2 instance profile name (like we did when attaching iam role to ec2 launch template) here because its not recognised
            },
			"Action": [
				"s3:GetObject",
				"s3:ListBucket",
				"s3:PutObject",
                "s3:DeleteObject"
			],

			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}",
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
            Condition = {
            StringEquals = {
                "aws:SourceVpce" = "${aws_vpc_endpoint.private_subnet_vpc_endpoint.id}"   # Dynamically insert VPC Endpoint ID
                }
            }
		}
	  ]
    }
  )
}


# Setup s3 event notification to trigger lambda when files are added to s3_normal_object_bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_normal_objects.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.static_upload_lambda_function.arn
    events              = ["s3:ObjectCreated:Put"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}








# Create the sesitive bucket
resource "aws_s3_bucket" "s3_sensitive_objects" {
  bucket = "s3-sensitive-objects-bucket"
}


# Add a policy to the sensitive object bucket. This will allow lambda to carry out only PUT and LIST actions on the bucket
resource "aws_s3_bucket_policy" "s3_sensitive_objects_bucket_policy" {
  bucket = aws_s3_bucket.s3_sensitive_objects.id

  policy = jsonencode(
    {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal" = "${aws_lambda_function.static_upload_lambda_function.arn}",
			"Action": [
				"s3:PutObject",
				"s3:ListBucket",
			],
			"Resource": [
				"${aws_s3_bucket.s3_sensitive_objects.arn}",
				"${aws_s3_bucket.s3_sensitive_objects.arn}/*"
			]
		}
	  ]
    }
  )
}



# Setup default encryption on s3_sensitive_object_bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_sensitive_encryption" {
  bucket = aws_s3_bucket.s3_sensitive_objects.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_sensitive_key.id
    }
  }
}



output "s3_normal_object_arn" {
  value = aws_s3_bucket.s3_normal_objects.arn
}


output "s3_sensitive_objects_arn" {
  value = aws_s3_bucket.s3_sensitive_objects.arn
}