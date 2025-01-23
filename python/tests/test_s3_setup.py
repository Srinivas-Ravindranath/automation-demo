import logging

import boto3
import pytest
from S3_Bucket_Setup.setup_buckets import SetupBuckets



@pytest.fixture
def s3_setup(mocked_aws):
    bucket_name = "cloud-computing-6907-81-terraform-state-bucket"
    key = "demo_deployment/"
    s3_client = boto3.client("s3", region_name="us-west-2") # bucket exists does not work with us-east-1
    yield bucket_name, s3_client, key

def test_s3_bucket_creation(s3_setup):
    bucket_name, s3_client, _ = s3_setup
    setup_buckets = SetupBuckets("us-west-2")
    setup_buckets.setup_s3_buckets()
    response = s3_client.list_buckets()
    assert any(bucket["Name"] == bucket_name for bucket in response["Buckets"])

def test_s3_bucket_object_creation(s3_setup):
    bucket_name, s3_client, key = s3_setup
    setup_buckets = SetupBuckets("us-west-2")
    setup_buckets.setup_s3_buckets()
    s3_object = s3_client.list_objects(
        Bucket=bucket_name, Prefix=key, Delimiter="/", MaxKeys=1
    )
    assert s3_object["Contents"][0]["Key"] == key

def test_s3_bucket_creation_when_exists(s3_setup, caplog):
    bucket_name, s3_client, _ = s3_setup
    s3_client.create_bucket(Bucket=bucket_name, ACL="private",CreateBucketConfiguration={"LocationConstraint": "us-west-2"})
    setup_buckets = SetupBuckets("us-west-2")
    with caplog.at_level(logging.WARNING):
        setup_buckets.setup_s3_buckets()

    assert "Bucket cloud-computing-6907-81-terraform-state-bucket already exists, skipping bucket creation.." in caplog.text


def test_s3_key_creation_when_exists(s3_setup, caplog):
    bucket_name, s3_client, key = s3_setup
    s3_client.create_bucket(Bucket=bucket_name, ACL="private",CreateBucketConfiguration={"LocationConstraint": "us-west-2"})
    s3_client.put_object(ACL="private", Bucket=bucket_name, Key=key)
    setup_buckets = SetupBuckets("us-west-2")
    with caplog.at_level(logging.WARNING):
        setup_buckets.setup_s3_buckets()
    assert "Object key demo_deployment/ already exists, skipping creation" in caplog.text
