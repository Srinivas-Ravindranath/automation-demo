import jenkins
import time
import logging

from Logger.formatter import CustomFormatter

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


class JenkinsApi:
    def __init__(self, jenkins_url, jenkins_username, jenkins_password):
        self.jenkins_server = jenkins.Jenkins(jenkins_url, username=jenkins_username, password=jenkins_password)
        user = self.jenkins_server.get_whoami()
        version = self.jenkins_server.get_version()
        logger.info("Jenkins Version: {}".format(version))
        logger.info("Jenkins User: {}".format(user['id']))

    def build_job(self, name, parameters=None, token=None):
        next_build_number = self.jenkins_server.get_job_info(name)['nextBuildNumber']
        self.jenkins_server.build_job(name, parameters=parameters, token=token)
        time.sleep(10)
        build_info = self.jenkins_server.get_build_info(name, next_build_number)
        return build_info
