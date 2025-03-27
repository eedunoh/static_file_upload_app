import os
import boto3
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    APP_SECRET_KEY = "myblogapp3353"  # Fixed value
    COGNITO_REGION = "eu-north-1"  # Fixed value. Change this to your AWS region

    @staticmethod
    def get_ssm_parameter(param_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=Config.COGNITO_REGION)
            response = ssm.get_parameter(Name=param_name, WithDecryption=with_decryption)
            return response["Parameter"]["Value"]
        except Exception as e:
            print(f"Warning: Unable to fetch {param_name} from SSM - {e}")
            return None

    @classmethod
    def initialize(cls):
        """Properly initializes class variables after the class is fully loaded."""
        cls.COGNITO_USER_POOL_ID = cls.get_ssm_parameter("cognito_user_pool_id")
        cls.COGNITO_CLIENT_ID = cls.get_ssm_parameter("cognito_client_id")
        cls.COGNITO_CLIENT_SECRET = cls.get_ssm_parameter("cognito_client_secret")

        # Ensure critical environment variables are set
        if not cls.COGNITO_CLIENT_ID:
            raise ValueError("COGNITO_CLIENT_ID is missing! Check your environment variables or SSM Parameter Store.")
        if not cls.COGNITO_CLIENT_SECRET:
            raise ValueError("COGNITO_CLIENT_SECRET is missing! Check your environment variables or SSM Parameter Store.")

# Explicitly initialize the class variables
Config.initialize()
