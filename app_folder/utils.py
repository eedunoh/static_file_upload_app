import boto3
import os
import hmac
import hashlib
import base64
import logging
from config import Config  # Import Config from config.py

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get required environment variables
COGNITO_REGION = Config.COGNITO_REGION
COGNITO_USER_POOL_ID = Config.COGNITO_USER_POOL_ID
COGNITO_CLIENT_ID = Config.COGNITO_CLIENT_ID
COGNITO_CLIENT_SECRET = Config.COGNITO_CLIENT_SECRET

# Validate environment variables
if not all([COGNITO_REGION, COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, COGNITO_CLIENT_SECRET]):
    raise ValueError("Missing required AWS Cognito environment variables.")

# Initialize Cognito client
cognito_client = boto3.client("cognito-idp", region_name=COGNITO_REGION)


def calculate_secret_hash(username):
    """
    Generate the SECRET_HASH required for Cognito authentication.
    """
    message = username + COGNITO_CLIENT_ID
    dig = hmac.new(COGNITO_CLIENT_SECRET.encode(), message.encode(), hashlib.sha256).digest()
    return base64.b64encode(dig).decode()


def authenticate_user(username, password):
    """
    Authenticate a user with AWS Cognito.
    Returns True if authentication is successful, otherwise False.
    """
    try:
        response = cognito_client.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": username,
                "PASSWORD": password,
                "SECRET_HASH": calculate_secret_hash(username),
            }
        )
        logger.info(f"User '{username}' authenticated successfully.")
        return response.get("AuthenticationResult") is not None
    except cognito_client.exceptions.NotAuthorizedException:
        logger.warning(f"Authentication failed for user '{username}'. Invalid credentials.")
        return False
    except cognito_client.exceptions.UserNotFoundException:
        logger.warning(f"Authentication failed: User '{username}' not found.")
        return False
    except Exception as e:
        logger.error(f"Unexpected error during authentication: {e}")
        return False


def register_user(username, password, email):
    """
    Register a new user in AWS Cognito.
    Returns True if registration is successful, otherwise False.
    """
    try:
        response = cognito_client.sign_up(
            ClientId=COGNITO_CLIENT_ID,
            Username=username,
            Password=password,
            SecretHash=calculate_secret_hash(username),
            UserAttributes=[{"Name": "email", "Value": email}],
        )
        logger.info(f"User '{username}' registered successfully.")
        return True
    except cognito_client.exceptions.UsernameExistsException:
        logger.warning(f"Registration failed: Username '{username}' already exists.")
        return False
    except cognito_client.exceptions.InvalidParameterException as e:
        logger.error(f"Invalid parameter error during registration: {e}")
        return False
    except cognito_client.exceptions.LimitExceededException:
        logger.error("Cognito request limit exceeded. Try again later.")
        return False
    except Exception as e:
        logger.error(f"Unexpected error during registration: {e}")
        return False
