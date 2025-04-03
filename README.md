# static_file_upload_app
This repository contains files needed to deploy a containerized static_file upload app on AWS with automated CI/CD and Iac.

## Architecture Diagram

![image](https://github.com/user-attachments/assets/93d51908-fe0e-484c-9ecf-7e9c6579882d)


## Project Structure

- **app.py**: Contains the core Flask application logic (routes for login, signup, and dashboard). Manages the login process with AWS Cognito and renders the homepage for authenticated users.
  
- **templates/**: Contains HTML files rendered by Flask for the frontend.
  - **signup.html**: Handles user registration.
  - **login.html**: Handles user login.
  - **home.html**: Displays the static file upload app homepage for authenticated users.
    
- **requirements.txt**: Specifies Python dependencies like Flask, boto3 (for AWS services), and any other libraries the app needs.
  
- **utils.py**: Includes helper functions like `authenticate_user()` and `register_user()` that interact with AWS Cognito for user authentication and sign-up.
  
- **config.py**: A configuration file that interacts with the AWS SSM Parameter store to fetch Cognito secrets, store environment variables and settings for the Flask application.
  
- **Dockerfile**: Contains instructions for building the Docker image (e.g., install dependencies, copy app code, run the app).
  
- **run.sh**: A shell script used to set environment variables (e.g., FLASK_APP, FLASK_ENV) and run the Flask application within the Docker container.
  
- **Jenkinsfile**: Defines the CI/CD pipeline, which automates pulling app files, building, testing, and deploying the app from GitHub, DockerHub to AWS using Jenkins and Terraform files.
  

### Terraform Setup

**terraform/**: Contains Terraform configuration files to provision AWS infrastructure.

Carefully plan how to declare and provision AWS resources. Basically, which resource should be provisioned first and which should come later. For this project, I followed this order:

1. **Main**: Create a `main.tf` file to store your providers and also select the VPC and subnets you will be using for this project.

2. **Cognito**: Cognito will be used for security and user authentication.

   - [AWS Terraform Cognito Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool)

3. **SSM Parameter Store**: We will store Cognito information and other secrets in AWS SSM Parameter Store. This will be used by the app to authenticate users.

   - [AWS Terraform SSM Parameter Store Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)

4. **KMS**: Create a KMS key for encrypting sensitive data. This key will be used to encrypt all objects stored in the sensitive objects s3 bucket by default.
   
    - [AWS Terraform KMS Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)

5. **S3 Buckets**: Create two (2) S3 buckets for storing data. The normal objects bucket will be the default storage for all uploaded files. The sensitive object bucket will be used to store files tagged 'sensitive'. Also, add bucket policies to confirm permission to access the buckets.
   
    - [AWS Terraform S3 Bucket Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

6. **Lambda Functions**: Create a Lambda function for serverless processing. When users upload new files to the normal object S3 bucket, S3 event notification triggers Lambda to move files tagged 'sensitive' to the KMS encrypted - sensitive objects S3 bucket for higher security. Note the lambda terraform-aws resource accepts a zipped lambda function file.
   
   - [AWS Terraform Lambda Function Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)

7. **Security Group**: Create security groups for application load balancer and EC2 instances. The EC2 security group should only accept traffic from the application load balancer.

   - [AWS Terraform Security Group Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)

10. **Application Load Balancer**: Create the application load balancer that will distribute traffic between all EC2 instances in the auto-scaling group. The Application load balancer will be launched in the public subnet of the VPC.

    - [AWS Terraform Application Load Balancer Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
    - [AWS Terraform Target Group Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)

    - We will create the target group of the application load balancer. Note that while creating the target group, we will not select any instance because that will be taken care of by the auto-scaling group.
     

9. **Auto Scaling Group & Launch Template**: Create the auto-scaling group that will scale the number of EC2 instances based on the policy used (for this project, we will use the 'TargetTrackingScaling' policy type with a threshold of 30%). The Auto Scaling group will be launched in the private seubnet of the VPC.
    
    - [AWS Terraform Auto Scaling Group Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
    - [AWS Terraform EC2 Launch Template Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)

    - We will create the EC2 launch template and attach a user data file. This file will contain all instructions that will run only at the launch of new instances.


10. **IAM Roles and Policies**: We need to create roles and attach policies to these roles.
    - Roles give permission/authority to AWS resources to carry out actions as an admin
    - Policies define what types of actions can be performed and on which AWS resource.

    - **Lambda IAM Role (iam_for_lambda)**: This role will grant the lambda function access to the two S3 buckets.
      
      - **S3 Access Policy (s3_access)**: This policy will be attached to the iam_for_lambda role.
        - The lambda function will only be able to LIST, PUT, GenerateDataKey and Decrypt objects in s3_sensitive_object_bucket.
        - It can also GET, LIST, GETObjectTagging and DELETE objects in s3_normal_object_bucket.

    
    - **EC2 Instance Role (ec2_instance_role)**: This role will be used inside the EC2 to grant the static file upload application access to AWS services or resources like SSM Parameter Store and s3_normal_object_bucket.
      
      - **SSM and S3 Access Policy (ssm_read_access_and_s3_access)**: This policy will be attached to the ec2_instance_role.
        - The static file upload application will be able to read parameters from the SSM Parameter Store and carryout PUT actions in s3_normal_object_bucket.
      
    - Finally, generate an IAM instance profile for this role. This will be attached to the EC2 in the launch template.
      
    - [AWS Terraform IAM role policy Configuration guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)
     


## Dependencies

- Flask
- boto3
- Other dependencies specified in `requirements.txt`

## Contact

For any inquiries, please contact [eedunoh@gmail.com].
