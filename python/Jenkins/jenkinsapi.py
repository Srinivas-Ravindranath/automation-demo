"""
Sets up the jenkins api client to run jenkins jobs remotely
"""

import logging
import time
from typing import List

import jenkins
from Logger.formatter import CustomFormatter

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


class JenkinsApi:
    """
    Class for setting up the jenkins api
    """
    def __init__(self, jenkins_url, jenkins_username, jenkins_password):
        # Create a jenkins api client
        self.jenkins_server = jenkins.Jenkins(
            jenkins_url, username=jenkins_username, password=jenkins_password
        )
        user = self.jenkins_server.get_whoami()
        version = self.jenkins_server.get_version()
        logger.info(f"Jenkins Version: {version}")
        logger.info(f"Jenkins User: {user['id']}")

    def build_job(self, name, parameters=None, token=None) -> List:
        """
        Builds the specified job passed to the function
        :param name: The name of the jenkins job to build
        :param parameters: The parameters to pass to the jenkins job if any
        :param token: The authentication token to be passed to the jenkins job
        :return:
        """
        next_build_number = self.jenkins_server.get_job_info(name)["nextBuildNumber"]
        self.jenkins_server.build_job(name, parameters=parameters, token=token)
        logger.info(f"Build started for {name}, waiting for it to finish...")
        time.sleep(10)
        build_info = self.jenkins_server.get_build_info(name, next_build_number)
        return build_info
