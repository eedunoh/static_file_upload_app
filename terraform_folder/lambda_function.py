
import json
import boto3

# AWS Clients
s3_client = boto3.client('s3')


# When an object is created, and s3 triggers lambda, below is a sample of a typical s3 notification event repsonse;

            #     {
            #   "Records": [
            #     {
            #       "eventTime": "2025-03-25T12:00:00Z",
            #       "eventName": "ObjectCreated:Put",
            #       "s3": {
            #         "bucket": { "name": "source-bucket" },
            #         "object": { "key": "uploaded-file.txt" }
            #       }
            #     }
            #   ]
            # }


# using the structure above, lambda can check if the event trigger is from s3
def lambda_handler(event, context):

 # event → Describes what triggered the Lambda function. It contains details of the event source, such as an API request, an S3 file upload, a DynamoDB stream update. This is the main input that the function processes.

 # context → Provides runtime information about the Lambda execution. It includes metadata like the function’s remaining execution time, allocated memory, request ID, and invocation source. This helps manage execution and logging.
    
    
    # lambda checks if there is a record in the event
    try:
        if 'Records' not in event:
            raise ValueError("Invalid event: No Records found")

        for record in event['Records']:
            bucket_name = record.get('s3', {}).get('bucket', {}).get('name')
            object_key = record.get('s3', {}).get('object', {}).get('key')

            if not bucket_name or not object_key:
                raise ValueError("Invalid event structure")

            print(f"Triggered bucket: {bucket_name}, Object: {object_key}")

            # Retrieve the latest object tags
            response = s3_client.get_object_tagging(Bucket=bucket_name, Key=object_key)
            tags = {tag['Key']: tag['Value'] for tag in response['TagSet']}

            print(f"Object Tags: {tags}")

            # check if the tag is sensitive
            if tags.get('sensitive') == 'true':
                print(f"Moving {object_key} to sensitive bucket")

                # if tag is sensitive, get the object (file)
                obj = s3_client.get_object(Bucket=bucket_name, Key=object_key)
                object_data = obj['Body'].read()

                # put the object in the s3-sensitive-objects-bucket
                s3_client.put_object(
                    Bucket='s3-sensitive-objects-bucket',
                    Key=object_key,
                    Body=object_data,
                    ContentType=obj.get('ContentType', 'application/octet-stream')
                )

                # delete the sensitive file from the normal bucket
                s3_client.delete_object(Bucket=bucket_name, Key=object_key)

            else:
                print(f"File {object_key} is not sensitive. No action taken.")

        return {"status": "Success"}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"status": "Error", "message": str(e)}



# use this Bash code to convert this function.py file to function.zip file. This is because the lambda resource only accepts a .zip file;    zip lambda_function.zip lambda_function.py
