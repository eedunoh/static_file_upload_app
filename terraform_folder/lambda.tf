
resource "aws_lambda_function" "static_upload_lambda_function" {
  function_name = "static_upload_lambda_function"    

  filename =   "lambda_function.zip"                # Name of the file that stores your function. If the file is not in the current working directory you will need to include a path.module in the filename.

  role = aws_iam_role.iam_for_lambda.arn            # iam role that grants permission to lambda to carryout actions on aws resources

  runtime = "python3.9"                             # This defines the programming language and environment AWS should use to run your function.

  handler = "lambda_function.lambda_handler"          # Specifies the function within your code that AWS Lambda should execute. It takes the form; "filename.function_name"
}