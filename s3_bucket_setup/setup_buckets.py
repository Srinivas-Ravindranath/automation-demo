import json
import logging

import boto3
from colorama import Fore

logger = logging.getLogger()

logger.setLevel(logging.INFO)


class SetupBuckets:
    def __init__(self, region: str):
        self.region = region
        self.s3_client = boto3.client("s3", region_name=region)

    def setup_s3_buckets(self):
        bucket_name = f"cloud-computing-6907-81-terraform-state-bucket"

        try:
            response = self.s3_client.create_bucket(Bucket=bucket_name, ACL="private")
            if response:
                logging.info(Fore.GREEN + f"Created bucket {bucket_name} successfully")

        except self.s3_client.exceptions.BucketAlreadyExists as e:
            logging.warning(
                Fore.RED
                + f"Bucket {bucket_name} already exists, skipping bucket creation.."
            )

        except self.s3_client.exceptions.BucketAlreadyOwnedByYou as e:
            logging.warning(
                Fore.RED
                + f"Bucket {bucket_name} already exists, skipping bucket creation.."
            )

        key = "demo_deployment/"

        object = self.s3_client.list_objects(
            Bucket=bucket_name, Prefix=key, Delimiter="/", MaxKeys=1
        )

        if not "Contents" in object:
            self.s3_client.put_object(ACL="private", Bucket=bucket_name, Key=key)

        logging.warning(Fore.RED + f"Object key {key} already exists, skipping creation")

        logging.info(
            Fore.GREEN + "Successfully created bucket and all objects with names \n",
            json.dumps(
                {"bucket_name": bucket_name, "bucket_key_prefix": key},
                indent=4,
                default=str,
            ),
        )


if __name__ == "__main__":
    SetupBuckets("us-east-1").setup_s3_buckets()
