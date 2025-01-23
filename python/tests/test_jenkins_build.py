import unittest
from unittest.mock import patch, MagicMock
from Jenkins import JenkinsApi

def test_build_job():
    
    with patch('Jenkins.jenkinsapi.jenkins.Jenkins') as mock_jenkins:

        mock_server = MagicMock()  
        mock_jenkins.return_value = mock_server

        mock_server.get_job_info.return_value = {"nextBuildNumber": 2}
        mock_server.get_build_info.return_value = {"status": "SUCCESS", "number": 1}

        jenkins_api = JenkinsApi("http://fake-jenkins", "user", "password")
        build_info = jenkins_api.build_job(name="test-job", parameters={"param1": "value1"})

        # mock_server.get_job_info.assert_called_once_with("test-job")
        mock_server.build_job.assert_called_once_with("test-job", parameters={"param1": "value1"}, token=None)
        # mock_server.get_build_info.assert_called_once_with("test-job", 42)

        assert build_info == {"status": "SUCCESS", "number": 1}