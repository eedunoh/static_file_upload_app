
# Something to note when defining policies;   "Effect": "Allow"  OR  Effect = "Allow" can be used. 

# They can be used interchangably

# JSON uses colons (:) and double quotes ("") 
# WHILE 
# Terraform HCL uses equals signs (=) without quotes for keys.




# Another thing to note in bucket policy is this; 

# IAM Role Policy can allow s3:CopyObject because it applies to the Lambda function performing the action.

# S3 Bucket Policy DOES NOT support s3:CopyObject directly. DON'T add it to the bucket policy, it will throw an error.  

# For the 's3:CopyObject' action to work, you ONLY need to have an IAM policy granting access to the Lambda function for the source and destination buckets.




# Create the normal bucket
resource "aws_s3_bucket" "s3_normal_objects" {
  bucket = "s3-normal-objects-bucket"
}



# Add a bucket policy to the normal object bucket.
resource "aws_s3_bucket_policy" "s3_normal_objects_bucket_policy" {
  bucket = aws_s3_bucket.s3_normal_objects.id

  policy = jsonencode(
    {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
					AWS = "${aws_iam_role.iam_for_lambda.arn}"  # This will allow lambda IAM role to carry out only GET, LIST, GETObjectTagging and DELETE actions on the bucket
				},
			"Action": [
				"s3:GetObject",
				"s3:ListBucket",
				"s3:GetObjectTagging",
				"s3:DeleteObject"
			],
			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}",
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
		},

		{
			"Effect": "Allow",
			"Principal": {
                	AWS = "${aws_iam_role.ec2_instance_role.arn}"   # Allow EC2 IAM role to carry out only PUT action on the bucket. We cant use ec2 instance profile name here (like we did when attaching iam role to ec2 launch template) because its not recognised.
            	},
			"Action": [
				"s3:PutObject"
			],

			"Resource": [
				"${aws_s3_bucket.s3_normal_objects.arn}",
				"${aws_s3_bucket.s3_normal_objects.arn}/*"
			]
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
    events              = ["s3:ObjectCreated:Put"]      # Lambda is triggered when a 'PutObject' event is created
  }

  depends_on = [aws_lambda_permission.allow_bucket]     # Depends on the lambda invoke function (this is defined in the lambda function terraform file). It gives permission to the s3 bucket to invoke lambda
}







# Create the sesitive bucket
resource "aws_s3_bucket" "s3_sensitive_objects" {
  bucket = "s3-sensitive-objects-bucket"
}


# Add a bucket policy to the sensitive object bucket. 
resource "aws_s3_bucket_policy" "s3_sensitive_objects_bucket_policy" {
  bucket = aws_s3_bucket.s3_sensitive_objects.id

  policy = jsonencode(
    {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
					AWS = "${aws_iam_role.iam_for_lambda.arn}"  # This will allow lambda to carry out only PUT and LIST actions on the bucket
				},
			"Action": [
				"s3:PutObject",
				"s3:ListBucket"
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






# something to note about s3 encryption;

# Amazon S3 automatically encrypts objects at rest using either SSE-S3 (default) or SSE-KMS (if configured like in this project).

# A user/role without KMS key permissions cannot access objects encrypted with SSE-KMS, even if they have S3 read permissions.

# In contrast, any user with S3 read access can access objects encrypted with SSE-S3, since no additional KMS permissions are required.

# In this project, I will use SSE-KMS to enforce stricter access control on the sensitive_object bucket.





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