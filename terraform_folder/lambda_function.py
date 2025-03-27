import boto3
import os

# AWS Clients
s3 = boto3.client('s3')

sensitive_bucket_name = "s3-sensitive-objects-bucket"

# To get an object tag, we use 'get_object_tagging()' function. It's a pre-defined function used to get object tags and has two paraneters; bucket_name and key(object_name). 
# The response usually comes in this form;

            # {
            #   "TagSet": [
            #     {
            #       "Key": "classification",
            #       "Value": "sensitive"
            #     },
            #     {
            #       "Key": "department",
            #       "Value": "finance"
            #     }
            #   ]
            # } 

# Then we extract the value ("sensitive") from the TagSet. We can define a new function to do that


def get_object_tags(bucket_name, object_key):
    response = s3.get_object_tagging(Bucket=bucket_name, Key=object_key)
    return response["TagSet"]




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
    # lambda checks if there is a record in the event, if the record is a list and the event being triggered is from s3
    record = event["Records"][0]

    if "Records" in event and "s3" in record and "bucket" in record["s3"] and "object" in record["s3"]:

        # lambda extracts necessary parameters
        record = event["Records"][0]
        triggered_bucket_name = record["s3"]["bucket"]["name"]     # the bucket that triggered lambda
        triggered_object = record["s3"]["object"]["key"]           # the object name that caused the trigger

        
        # lambda gets object tags using the 'get_object_tags()' function defined earlier
        tags = get_object_tags(triggered_bucket_name, triggered_object)

        
        # lambda checks if file is tagged sensitve and moves file to sensitive s3 bucket
        is_sensitive = False
        for tag in tags:
            if tag["Key"] == "classification" and tag["Value"] == "sensitive":
                is_sensitive = True
                break  # Stop once found
        
        
        if is_sensitive:

            # Copy the object to destionaltion (sensitive) bucket
            s3.copy_object (                
                CopySource = {
                            'Bucket': triggered_bucket_name,
                            'Key': triggered_object
                            },
                Bucket = sensitive_bucket_name, 
                Key = triggered_object
                )

            # Delete sensitive object from source (normal) bucket
            s3.delete_object(Bucket = triggered_bucket_name, Key = triggered_object)

            print(f"Moved {triggered_object} to {sensitive_bucket_name}")

        else:
            print(f"File {triggered_object} is not sensitive. No action taken.")

    return None