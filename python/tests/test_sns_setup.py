import logging

import boto3
import pytest
from SNS_Setup.create_sns_notifier import CreateSnsNotifier


@pytest.fixture
def sns_setup(mocked_aws):
    sns_name = "cloud-demo-notifier"
    sns_client = boto3.client("sns", region_name="us-east-1")
    yield sns_client, sns_name


def test_sns_topic_exists(sns_setup):
    sns_client, sns_name = sns_setup
    response = sns_client.create_topic(Name=sns_name)
    sns_notifier = CreateSnsNotifier("us-east-1", "test@example.com")
    assert sns_notifier.sns_topic_exists(response["TopicArn"]) == True


def test_sns_subscription_exists(sns_setup):
    sns_client, sns_name = sns_setup
    response = sns_client.create_topic(Name=sns_name)
    sns_client.subscribe(
        Endpoint="test@example.com", TopicArn=response["TopicArn"], Protocol="email"
    )
    sns_notifier = CreateSnsNotifier("us-east-1", "test@example.com")
    assert (
        sns_notifier.sns_topic_subscription_exists(
            response["TopicArn"], "test@example.com"
        )
        == True
    )


def test_setup_sns_notifier_create(mocked_aws):
    sns_notifier = CreateSnsNotifier("us-east-1", "test@example.com")
    sns_notifier.setup_sns_notifier()
    assert (
        sns_notifier.sns_topic_exists(
            "arn:aws:sns:us-east-1:123456789012:cloud-demo-notifier"
        )
        == True
    )


def test_setup_sns_subscription_create(mocked_aws):
    sns_notifier = CreateSnsNotifier("us-east-1", "test@example.com")
    sns_notifier.setup_sns_notifier()
    assert (
        sns_notifier.sns_topic_subscription_exists(
            "arn:aws:sns:us-east-1:123456789012:cloud-demo-notifier", "test@example.com"
        )
        == True
    )


def test_setup_sns_topic_not_created(sns_setup, caplog):
    sns_client, sns_name = sns_setup
    sns_client.create_topic(Name=sns_name)
    sns_notifier = CreateSnsNotifier("us-east-1", "test@example.com")
    with caplog.at_level(logging.INFO):
        sns_notifier.setup_sns_notifier()
    assert (
        "SNS topic arn:aws:sns:us-east-1:123456789012:cloud-demo-notifier already exists"
        in caplog.text
    )
