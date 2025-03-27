resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "cognito_user_pool_id"
  type  = "String"
  value = aws_cognito_user_pool.my_user_pool.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "cognito_client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.my_user_pool_client.id
}

resource "aws_ssm_parameter" "cognito_client_secret" {
  name  = "cognito_client_secret"
  type  = "String" # Secure value!
  value = aws_cognito_user_pool_client.my_user_pool_client.client_secret
}
