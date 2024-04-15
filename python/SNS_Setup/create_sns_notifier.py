"""
Creates SNS notifier topic for the cloud demo project
"""

import logging
import argparse

import boto3

from Logger.formatter import CustomFormatter

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


class CreateSnsNotifier:
    """
    Class responsible for creating a SNS notifier
    """

    def __init__(self, region, email):
        self.region = region
        self.sns_client = boto3.client("sns", region_name=region)
        self.sts_client = boto3.client("sts")
        self.sns_name = "cloud-demo-notifier"
        self.account_id = self.sts_client.get_caller_identity()["Account"]
        self.email = email

    def sns_topic_exists(self, topic_arn: str) -> bool:
        """
        Checks if the SNS Topic exists or not
        :param topic_arn:
        :return: bool
        """

        try:
            response = self.sns_client.get_topic_attributes(TopicArn=topic_arn)
            if response:
                logger.warning(f"SNS topic {topic_arn} already exists")
                return True
        except self.sns_client.exceptions.NotFoundException:
            return False

        return False

    def sns_topic_subscription_exists(self, topic_arn, email: str) -> bool:
        """
        Checks if the SNS Topic subscription exists or not
        :param topic_arn: str
        :param email: str
        :return:
        """

        response = self.sns_client.list_subscriptions()
        subscription_exists = any(
            subscription["Endpoint"] == email and subscription["TopicArn"] == topic_arn
            for subscription in response["Subscriptions"]
        )

        if not subscription_exists:
            return False

        logger.warning(
            f"SNS topic subscription to email {email} already exists for topic {topic_arn}"
        )
        return True

    def setup_sns_notifier(self) -> None:
        """
        Creates the SNS topics and Email subscriptions for
        the cloud demo
        :return: None
        """

        sns_name = "cloud-demo-notifier"
        account_id = self.sts_client.get_caller_identity()["Account"]
        sns_check_arn = f"arn:aws:sns:{self.region}:{account_id}:{sns_name}"

        if not self.sns_topic_exists(sns_check_arn):
            response = self.sns_client.create_topic(Name=sns_name)
            sns_topic_arn = response["TopicArn"]

            if not sns_topic_arn:
                print(f"Unable to create SNS topic {sns_name}, please try again")

            print(
                f'Successfully created cloud-demo notifier topic: {response["TopicArn"]}'
            )

            try:
                if not self.sns_topic_subscription_exists(
                    email=self.email, topic_arn=sns_topic_arn
                ):
                    response = self.sns_client.subscribe(
                        TopicArn=sns_topic_arn, Protocol="email", Endpoint=self.email
                    )

                    if response["SubscriptionArn"]:
                        print("Successfully subscribed to cloud-demo-notifier topic")

            except self.sns_client.exceptions.NotFoundException:
                print(
                    "Unable to add subscription to cloud-demo-notifier, "
                    "please check if topic ARN is correct"
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get Jenkins Credentials")
    parser.add_argument(
        "--email",
        type=str,
        help="email for SNS notifier",
        required=True,
        dest="email",
    )
    args = parser.parse_args()
    CreateSnsNotifier(region="us-east-1", email=args.email).setup_sns_notifier()
