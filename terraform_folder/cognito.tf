# Cognito User Pool
resource "aws_cognito_user_pool" "my_user_pool" {
  name = "static_file_app_user_pool"

  deletion_protection = "INACTIVE"
  auto_verified_attributes = ["email"]
  mfa_configuration = "OFF"

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                   = true
    require_symbols                   = true
    require_uppercase                 = true
    password_history_size             = 0
    temporary_password_validity_days  = 7
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  username_configuration {
    case_sensitive = false
  }

  user_pool_tier = "ESSENTIALS"

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option   = "CONFIRM_WITH_LINK"
    email_message_by_link  = "Please click the link below to verify your email address. {##Verify Email##}. Stay Informed! Thanks for joining!"
    email_subject_by_link  = "Your static file app verification link"
  }

}



resource "aws_cognito_user_pool_client" "my_user_pool_client" {
  name         = "my-static-file-app"
  user_pool_id = aws_cognito_user_pool.my_user_pool.id

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 5

  generate_secret     = true      # generate app client secret

  allowed_oauth_flows                   = ["code"]
  allowed_oauth_flows_user_pool_client  = true
  allowed_oauth_scopes                   = ["email", "openid", "phone"]

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  supported_identity_providers = ["COGNITO"]

  callback_urls = [
    "https://d84l1y8p4kdic.cloudfront.net"          # A callback URL is the URL where users are redirected after successful email authentication with Cognito.
  ]
}



# Configure Cognito Domain

resource "aws_cognito_user_pool_domain" "my_domain" {
  domain       = "myapp-static-file"                              # The Cognito domain is needed for OAuth token exchange between the app and cognito. It works behind the scene.
  user_pool_id = aws_cognito_user_pool.my_user_pool.id
}





output "user_pool_id" {
  value = aws_cognito_user_pool.my_user_pool.id
}


output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.my_user_pool_client.id
}


output "user_pool_client_secret" {
  value = aws_cognito_user_pool_client.my_user_pool_client.client_secret
  sensitive = true
}