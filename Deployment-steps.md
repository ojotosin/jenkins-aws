
# 1. Add SSH key Pair to AWS Parameter Store
ssh-keygen /home/jesusiscariot/Documents/id_rsa

AWS > Parameter Store > 
for private key;
name = /devops-tools/jenkins/id_rsa
Description = jenkins SSH private key
Standard, SecureString
Paste the value
Create parameter

for public key;
name = /devops-tools/jenkins/id_rsa.pub
Description = jenkins SSH public key
Standard, SecureString
Paste the value
Create parameter

# 2. Create IAM Role for Jenkins Agent
cd terraform/iam

terraform init
terraform plan
terraform apply --auto-approve

# 3. Create EFS Using Terraform
cd terraform/efs

update the vpc and subnet id in the efs (main.tf) file

terraform init
terraform plan
terraform apply --auto-approve

validate the provisioned EFS from the AWS console
AWS > EFS > select the just created EFS 
check the network
copy the DNS name

# 4. Create Jenkins Controller & Agent AMIs
cd to home folder

- Build Jenkins Controller AMI
Replace the ami-id in jenkins-controller.pkr.hcl file
Replace the DNS in the following command with the EFS DNS endpoint:
Execute the jenkins-controller.pkr.hcl Packer configuration file with the EFS DNS endpoint. 

`packer build -var "efs_mount_point=fs-05630cc17c807144a.efs.us-west-2.amazonaws.com" jenkins-controller.pkr.hcl`

note down the ami-id, as it will be needed during autoscaling setup

- Build Jenkins Agent AMI
Replace the ami id on in jenkins-agent.pkr.hcl file
Execute the jenkins-agent.pkr.hcl Packer configuration.
pass the /devops-tools/jenkins/id_rsa.pub path from the AWS Parameter Store as a variable.

`packer build -var "public_key_path=/devops-tools/jenkins/id_rsa.pub" jenkins-agent.pkr.hcl`

Upon successful execution, you will see the registered jenkins-agent AMI id in the terminal output.

# 5. Deploy Jenkins Controller Autoscaling Group & Load Balancer
cd terraform/asg-lb
Replace the subnets in the terraform/asg-lb/main.tf
Replace the key name with your ssh keypair name
Replace AMI Id with the AMI id of your Jenkins controller AMI Id
Replace VPC Id with your VPC Id.

terraform init
terraform plan 
terraform apply --auto-approve

- validate by checking the aws console for
autoscaling, click on the target group to check it's health
load balancer: copy the load balancer dns and paste on a browser to check that the controller is operational


- get the public IP of the Jenkins-controller instance using the following CLI command:

`aws ec2 describe-instances --filter "Name=tag:Name,Values=jenkins-controller" --query 'Reservations[].Instances[?State.Name==`running`].PublicIpAddress' --output text`

copy the IP of the controller displayed on the command line


- Login to the server and get the admin password.
ssh into the instance using the keypair you provided during the setup

`ssh -i ~/Downloads/my-us-west-keypair.pem ubuntu@ip_address_of_controller`

- Display the initial password, copy and paste to unlock jenkins

`sudo cat /data/jenkins/secrets/initialAdminPassword`

- Create admin user and log into jenkins


# 6. Deploy Jenkins Agent
cd terraform/agent
Replace the subnets IDs in the terraform/agent/main.tf
Replace the key name with your ssh keypair name
Replace AMI Id with the AMI id of your Jenkins agent AMI Id
If you want more than one Jenkins agent, you can replace the instance_count number with the required number of agents.

copy the IP address of the agent node

- Configure Agent with Jenkins Controller Node 
Jenkins > Manage jenkins > Manage Nodes and Clouds > New Node > name + permanent agent
Name = Agent01
Description = Jenkins SSH agent
Remote root directory = /home/ubuntu
Labels = AGENTO1
Launch method = Launch agent via SSH
Host = ip_of_the_Jenkins_agent_node
Credentials = Jenkins
    Kind = SSH username with private key
    ID = jenkins-SSH-cred
    Description = SSH auth for Agent01
    Username = ubuntu (it's the default sudo user for ubuntu which is the base ami for agent01)
    private Hey = copy and paste from AWS parameter store
    Add
Select the just created credential
Host Key Verification Strategy = Non verifying Verification Strategy
Save

- Verify that it has connected
check the agent logs to verify the connection.

- Create a freestyle job to test
New item > name + freestyle + create
Restrict where this project can be run > AGENT01
Build Steps > Execute shell

echo "Hello World"

Apply + save
Build Now

# 7.  Test Jenkins High Availability
To test the Jenkins availabilty by terminating the controller instance
Check to see if another instance comes up and mounts to the efs properly having data and config intact
Check the target group, you'll see 0 healthy instance
Give it a few minutes, the instance will be back up by itself and the target group healthy with 1 instance 
Check the load balancer dns to see if the new instance is using the efs mount and that the data is consistent with previous instance
Login again to the jenkins controller and verify

# 8.  Patching & Upgrading Jenkins Controller
Upgrading/Patching Jenkins with a newer version the Immutable Way
 Every organization servers must be patched monthly with the latest OS patches for security compliance
 If you follow an immutable model, when there is a patch or security upgrade you can not do it in existing VMs
 You need to create a new ami with required patches and application upgrade then replace the existing servers with servers from the new AMI

To upgrade jenkins to a new server
- create a new AMI with the required patches, upgrade and configurations and name it using packer
- Update the new AMI id in the terraform configuration







##  Clean Up
- Execute terraform destroy from the respective Terraform folder.
agent,asg-lb, efs, iam
- To deregister the AMIs, use the following AWS CLI commands

`aws ec2 describe-images --filters "Name=name,Values=jenkins-controller,jenkins-agent" --query 'Images[*].ImageId' --output text | tr '\t' '\n' | xargs -I {} aws ec2 deregister-image --image-id {}`

- To delete the parameter store values, use the following command.

aws ssm delete-parameter --name /devops-tools/jenkins/id_rsa
aws ssm delete-parameter --name /devops-tools/jenkins/id_rsa.pub
