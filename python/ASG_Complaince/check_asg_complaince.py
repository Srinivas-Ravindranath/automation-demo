"""
This script goes through all the Autoscaling Groups and
returns a list of all asg instances running non complaint
AMI's

TODO:
1) Fix instance attributes in __init__ function
2) Improve Code quality
"""

import json
import sys
import logging
import argparse
from typing import Dict

import boto3

from Logger.formatter import CustomFormatter
from JenkinsApi.jenkinsapi import JenkinsApi

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


class GetLatestAMI:
    """
    Class to get non complaint asg instances
    """

    def __init__(self, region):
        self.region = region
        self.ec2_client = boto3.client("ec2", region_name=region)
        self.autoscaling_client = boto3.client("autoscaling", region_name=region)
        self.sns_client = boto3.client("sns", region_name=region)
        self.sts_client = boto3.client("sts")
        self.sns_name = "cloud-demo-notifier"
        # Get account id for the AWS account
        self.account_id = self.sts_client.get_caller_identity()["Account"]
        self.sns_notifier_arn = (
            f"arn:aws:sns:{region}:{self.account_id}:{self.sns_name}"
        )
        # Replace the url to whichever port setup by user
        self.jenkins_url = "http://localhost:8080"
        parser = argparse.ArgumentParser(description="Get Jenkins Credentials")
        parser.add_argument(
            "--jenkinsUser",
            type=str,
            help="Jenkins username for jenkinsapi",
            required=True,
            dest="jenkinsUser",
        )

        parser.add_argument(
            "--jenkinsPass",
            type=str,
            help="Jenkins username for jenkinsapi",
            required=True,
            dest="jenkinsPass",
        )

        args = parser.parse_args()
        self.jenkins_api = JenkinsApi(
            jenkins_url=self.jenkins_url,
            jenkins_username=args.jenkinsUser,
            jenkins_password=args.jenkinsPass,
        )
        self.asg_information = {}
        self.non_complaint_asgs = {}
        self.triggered_jobs = {}

    @staticmethod
    def filter_asg_tags(tags: list) -> dict:
        """
        Filter asg tags as it contains non-relevant tags and
        return only tags related to AMI images
        :param tags: list
        :return: dict
        """
        filtered_tags = {}
        required_tags = [
            "image-name",
            "owners",
            "root-device",
            "virtualization-type",
            "jenkins_job_name",
        ]
        try:
            for tag in tags:
                if tag["Key"] in required_tags:
                    filtered_tags[tag["Key"]] = tag["Value"]
        except KeyError as e:
            logger.warning("Unable to filter tags: {}".format(e))
            return {}

        return filtered_tags

    def get_latest_ami(self, image_details: Dict) -> str:
        """
        Returns the latest AMI id for the given OS image required
        :param image_details: Dict
        :return: str
        """
        try:
            images = self.ec2_client.describe_images(
                Filters=[
                    {"Name": "name", "Values": [image_details["image_name"]]},
                    {
                        "Name": "virtualization-type",
                        "Values": [image_details["virtualization_type"]],
                    },
                    {
                        "Name": "root-device-type",
                        "Values": [image_details["root_device_type"]],
                    },
                ],
                Owners=[
                    image_details["image_owner"],
                ],
            )
            latest_ami = sorted(
                images["Images"], key=lambda x: x["CreationDate"], reverse=True
            )[0][
                "ImageId"
            ]  # Sort AMI images by latest date(default returns all in ascending order of date)

            return latest_ami

        except self.ec2_client.exceptions.ParamValidationError as e:
            logger.error(f"Invalid parameter reference to describe_images: {e}")
            sys.exit(1)

        except self.ec2_client.exceptions.InvalidQueryParameter as e:
            logger.error(f"Invalid query parameter for describing imaged: {e}")
            sys.exit(1)

    def gather_instance_information(self) -> None:
        """
        Gathers all information about all auto-scaling groups
        and its associated instances
        :return: None
        """
        asg_paginator = self.autoscaling_client.get_paginator(
            "describe_auto_scaling_groups"
        ).paginate()
        asg_info = []
        for page in asg_paginator:
            try:
                for asg in page["AutoScalingGroups"]:
                    asg_name = asg["AutoScalingGroupName"]
                    asg_tags = asg["Tags"]
                    asg_instances = []
                    for instance in asg["Instances"]:
                        instance_id = instance["InstanceId"]
                        ec2_information = self.ec2_client.describe_instances(
                            InstanceIds=[instance_id]
                        )["Reservations"][0]["Instances"][0]
                        image_id = ec2_information["ImageId"]
                        asg_instances.append(
                            {"instance_id": instance_id, "image_id": image_id},
                        )
                    asg_info.append(
                        {
                            asg_name: {
                                "asg_tags": asg_tags,
                                "asg_instances": asg_instances,
                            }
                        }
                    )
            except KeyError as e:
                logger.error(f"Unexpected Key: {e}")
                exit(1)

        self.asg_information["AutoScalingGroups"] = asg_info

    def check_non_complaint_asgs(self) -> None:
        """
        Compares all auto-scaling group instance image id with
        the latest image id and marks all instances that are not complaint
        :return: None
        """
        self.gather_instance_information()
        non_complaint_asgs = []
        for asg in self.asg_information["AutoScalingGroups"]:
            for asg_name in asg.keys():
                filtered_tags = self.filter_asg_tags(asg[asg_name]["asg_tags"])
                required_tags = [
                    "image-name",
                    "owners",
                    "root-device",
                    "virtualization-type",
                    "jenkins_job_name",
                ]
                if not all(key in filtered_tags for key in required_tags):
                    logger.warning(
                        f"Invalid tagging for resource, "
                        f"unable to determine for tags for asg, skipping {asg_name}"
                    )
                    continue

                latest_ami = self.get_latest_ami(
                    {
                        "image_name": filtered_tags["image-name"],
                        "image_owner": filtered_tags["owners"],
                        "virtualization_type": filtered_tags["virtualization-type"],
                        "root_device_type": filtered_tags["root-device"],
                    }
                )

                for instances in asg[asg_name]["asg_instances"]:
                    if instances["image_id"] != latest_ami:
                        non_complaint_asgs.append(
                            {
                                "instance-id": instances["instance_id"],
                                "jenkins_job_name": filtered_tags["jenkins_job_name"],
                            }
                        )

                if not non_complaint_asgs:
                    logger.info(f"No Non Complaint AMIs Found for ASG {asg_name}")
                    continue

                self.non_complaint_asgs[asg_name] = non_complaint_asgs

        if not self.non_complaint_asgs:
            logger.info(
                "All ASG are running the latest AMI for the specified OS, "
                "No non complaint resources found."
            )
            # Publish to SNS notifier
            self.sns_client.publish(
                TopicArn=self.sns_notifier_arn,
                Subject="AMI compliance report for Auto Scaling Groups",
                Message="All ASG are running the latest AMI for the specified OS, "
                "No non complaint resources found.",
            )
            return

        logger.info(
            f"Non Complaint AMIs found running in the region {self.region}, "
            f"listing non-complaint ASG below: "
            f"\n {json.dumps(self.non_complaint_asgs, indent=4, default=str)}"
        )

        # Call all related jenkins jobs for updating the AMI on ASG
        for asg in self.non_complaint_asgs.keys():
            output = self.jenkins_api.build_job(
                self.non_complaint_asgs[asg][0]["jenkins_job_name"],
            )
            logger.info(f'Jenkins Build URL: {output["url"]}')
            self.triggered_jobs[asg] = output["url"]

        # Publish to SNS notifier
        self.sns_client.publish(
            TopicArn=self.sns_notifier_arn,
            Subject="AMI compliance report for Auto Scaling Groups",
            Message=f"Non Complaint AMIs found running in the region {self.region}, "
            f"listing non-complaint ASG below: "
            f"\n {json.dumps(self.non_complaint_asgs, indent=4, default=str)} \n"
            f"The jenkins jobs mentioned in the AMI compliance report have been started to update AMI,"
            f"please approve requests for the terraform deployment to update the ami, "
            f"the following Jenkins job have been triggered below: "
            f"\n {json.dumps(self.triggered_jobs, indent=4,default=str)}",
        )


if __name__ == "__main__":
    get_latest_ami = GetLatestAMI("us-east-1")
    get_latest_ami.check_non_complaint_asgs()
