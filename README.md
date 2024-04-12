# Automation-demo

This project demonstrates how we can setup a basic automation using Jenkins and Terraform on the AWS Cloud

<h3>Prerequisites:</h3>

1) <b>AWS Cli:</b> <br>
    ```
    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    ```
    
2) <b>Python3:</b> <br>
    ```angular2html
    https://www.python.org/downloads/
    ```
3) <b>Jenkins:</b> <br>
   ```angular2html
    https://www.jenkins.io/doc/book/installing/
   ```
4) <b>Terraform:</b> <br>
   ```angular2html
    https://developer.hashicorp.com/terraform/install?product_intent=terraform
   ```

<h3>Setting up the tools:</h3>

<h4>Setting up AWS Cli:</h4>

1) Open your AWS management console on your browser and open up the IAM service.
2) Create a new user using the user section on page. <br>
   !["Creating_user"](./images/user_Creation.png)
3) Click on create user option and in the creation screen give a friendly name to this user.
4) Next click on <b>Attach policies directly</b> option and attach the <b>PowerUserAccess</b> policy to the user. <br>
   <b>Note: Attaching poweruserplus access is not the best practise always ensure every service gets only the correct amount 
         permissions. (only use poweruserplus for the demo).</b><br>
    !["Creating_user"](./images/add_permission.png)
5) After attaching the policy go ahead and create the user.
6) Now click on the newly created user and navigate to the security credentials option and scroll down to find the <b>
   Create Access Key</b> button. <br>
7) Chose the <b>Command Line Interface</b> and tick the confirmation statement below and click on the next button.
    !["Creating_user"](./images/creating_access_key.png)
8) Click on the download CSV to get the <b>Access Key</b> and <b>Secret Key</b> which we will use for later.
    !["Creating_user"](./images/download_csv.png)
9) Run the following command to check aws cli is installed.
   ```
   aws --version
   ```
10) Run the below command to add your credentials to interact with AWS.
    ```
    aws configure
    ```
11) Enter the Access Key and Secret from the csv file downloaded from the console and use us-east-1 as the default region. <br>
    !["Creating_user"](./images/configure.png)
12) Run the below query to test if the aws credentials are configured correctly.

    ```
    aws s3 ls --region us-east-1
    ```
    The command should either return nothing or some buckets if you have any, if you receive an error that indicates that
    the credentials are not configured correctly.

<h3>Setting up Python3:</h3>

<h4>Mac Setup</h4>

```
brew install python3
```
Note: Already installed on the system in case it is not please use the below command.<br>



<h4>Linux Setup</h4>

```
sudo apt install python3
```
Note: Already installed on the system in case it is not please use the below command.<br>


<h3>Setting up the python environment for local testing</h3>

Please follow the below steps to setup a virtualenv for the environment:
```
cd /path-to-dir/automation-demo/python
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
python3 python_file_to_execute.py
```


<h3>Setting  up Terraform</h3>

Setting up terraform on Mac:
```angular2html
brew install terraform
terraform --version
```
Setting up terraform on Linux:
```
#Install Dependencies

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Install the GPG key

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

#Verify the key's GPG key

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

#Add the official HashiCorp repository to your system

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

#Download the package information from Hashicorp

sudo apt update

# Install Terraform

sudo apt-get install terraform
```

<h3>Setting up Jenkins</h3>

<h4>Setting up Jenkins on Mac:</h4>

```
brew install jenkins
brew services start jenkins
```

<h4>Setting up Jenkins on Linux:</h4>

```
#Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > \
/etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```
Follow the setup instructions on the browser to complete the setup.

<h3>Setting up the Jenkins Credentials</h3>

<h4>Setting up Github ssh login:</h4>
1) Create a ssh key using the below command:

    ```
   ssh-keygen -t rsa -b 4096 -C "your_email"
    ```
2) Copy the public key using the below command: 
    
    ```
   cat ~/.ssh/id_rsa.pub
    ```
3) Go to the Github settings and click on the SSH and GPG keys option and click on the new SSH key option. <br>
4) Paste the copied key in the key section and give a title to the key and click on the add SSH key button. <br>
5) Now go to the Jenkins dashboard and click on the Manage Jenkins button. <br>
6) Click on the Manage Credentials option and click on the global credentials domain. <br>
7) Click on the Add Credentials option and select the SSH Username with private key option. <br>
8) Enter the username as <b>GITHUB_ACCESS_KEY</b> and select the private key as the key option and paste the private key in the key section. <br>
9) Click on the OK button to save the credentials. <br>

<h4>Setting up Jenkins Credentials</h4> 
1) Now go to the Jenkins dashboard and click on the Manage Jenkins button. <br>
2) Click on the Manage Credentials option and click on the global credentials domain. <br>
3) Click on the Add Credentials option and select the Username and password option. <br>
4) Enter the ID as <b>JENKINS_LOGIN_CREDENTIALS</b> and enter the username and password of the Jenkins login. <br>
5) Click on the OK button to save the credentials.

<h4>Setting up the Jenkins Pipeline</h4> 
1) Click on the New Item option on the Jenkins dashboard. <br>
2) Enter the item name as <b>name_of_the_job_you_want_to_create</b> and select the pipeline option. <br>
3) Click on the OK button to create the pipeline. <br>
4) In the pipeline section, paste one of the Jenkinfiles from the Jenkinsfiles directory. <br>
5) Click on the Save button to save the pipeline. <br>
6) Click on the Build Now or Build With Parameters button to build the pipeline. <br>
7) The parameterized pipelines are already prefilled with default values so you can just click on the build button to start the pipeline. <br>
8) The pipeline will start and you can see the logs in the console output section. <br>


<h4>What each Jenkinsfile does:</h4> 
1) <b>deploy_s3_bucket:</b> This Jenkinsfile is used to deploy an S3 bucket that is required for storing the terraform state files using python3 and boto3. <br>
2) <b>cloud_demo_deployment:</b> This Jenkinsfile is used to deploy the cloud infrastructure(infrastructure mentioned in the diagrams->aws_arch.jpg) using terraform. <br>
3) <b>cloud_demo_deployment_destroy:</b> This Jenkinsfile is used to destroy the cloud infrastructure(infrastructure mentioned in the diagrams->aws_arch.jpg) using terraform. <br>
4) <b>non_complaint_asg:</b> This Jenkinsfile is used to check for non-compliant ASG instances and alert the user that the instances are non-compliant and also trigger a deployment job that will make update the instances to be compliant. <br>
5) <b>set_old_ami_for_deployment:</b> This Jenkinsfile is used to set the old AMI for the ASG to test whether the non_complaint_asg jenkins job can detect it and update the ASG's. <br>
6) <b>create_patch_policy:</b> This Jenkinsfile is used to create a patch policy for that ensures that the EC2 instances are updated with the latest patches every week at a set maintenance window. <br>
7) <b>delete_patch_policy:</b> This Jenkinsfile is used to delete the patch policy that was created using the create_patch_policy Jenkinsfile. <br>