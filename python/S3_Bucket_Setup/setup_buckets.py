"""
Script to setup the S3 bucket required to store the terraform state buckets
Not created with terraform as there no place to store state file
"""

import json
import logging
from random import randint


import boto3

from Logger.formatter import CustomFormatter

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


class SetupBuckets:
    """
    Class to setup the S3 bucket required to store the terraform state file
    """

    def __init__(self, region: str):
        self.region = region
        self.s3_client = boto3.client("s3", region_name=region)

    def setup_s3_buckets(self) -> None:
        """
        Create the S3 bucket required to store the terraform state and also
        the S3 key path
        :return: None
        """
        bucket_name = f"cloud-computing-6907-81-terraform-state-bucket-{str(randint(1,100))}"

        try:
            response = self.s3_client.create_bucket(Bucket=bucket_name, ACL="private")
            if response:
                logging.info(f"Created bucket {bucket_name} successfully")

        # Doesnt work with us-east-1 region(https://github.com/boto/boto3/issues/4023)
        except self.s3_client.exceptions.BucketAlreadyExists:
            logging.warning(
                f"Bucket {bucket_name} already exists, skipping bucket creation.."
            )

        except self.s3_client.exceptions.BucketAlreadyOwnedByYou:
            logging.warning(
                f"Bucket {bucket_name} already exists, skipping bucket creation.."
            )

        key = "demo_deployment/"

        # Check if the S3 key already exists else skip key creation
        s3_object = self.s3_client.list_objects(
            Bucket=bucket_name, Prefix=key, Delimiter="/", MaxKeys=1
        )

        if not "Contents" in s3_object:
            self.s3_client.put_object(ACL="private", Bucket=bucket_name, Key=key)

        logging.warning(f"Object key {key} already exists, skipping creation")

        logging.info(
            "Successfully created bucket and all objects with names:\n%s",
            json.dumps(
                {"bucket_name": bucket_name, "bucket_key_prefix": key},
                indent=4,
                default=str,
            ),
        )


if __name__ == "__main__":
    SetupBuckets("us-east-1").setup_s3_buckets()
