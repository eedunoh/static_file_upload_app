# Create lambda resource
resource "aws_lambda_function" "static_upload_lambda_function" {
  function_name = "static_upload_lambda_function"    

  filename =   "lambda_function.zip"                # Name of the file that stores your function. If the file is not in the current working directory you will need to include a path.module in the filename.

  role = aws_iam_role.iam_for_lambda.arn            # iam role that grants permission to lambda to carryout actions on aws resources

  runtime = "python3.9"                             # This defines the programming language and environment AWS should use to run your function.

  handler = "lambda_function.lambda_handler"        # Specifies the function within your code that AWS Lambda should execute. It takes the form; "filename.function_name"
}




# Create a lambda:InvokeFunction. This is important because S3 needs explicit permission to invoke Lambda.
# When using the AWS Management Console, AWS automatically adds the required Lambda:InvokeFunction permission behind the scenes. In terraform, we need to explicitly configure it.

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.static_upload_lambda_function.function_name    # DON'T use function_arn in the place of function_name 
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_normal_objects.arn     # This is the s3 bucket (normal_object_bucket) allowed to invoke/ trigger lambda
}