# jenkins-aws
jenkins aws setup using terraform, ansible and packer

## structure of the IaC code
- jenkins-controller.pkr.hcl and jenkins-agent.pkr.hcl are Packer configuration files, which internally call the Ansible playbook inside the ansible folder.
- The ansible folder contains the roles that the playbook uses.
- Terraform provisioning logic is located in modules under the modules folder. To provisionresources, we use separate Terraform configuration files that call the modules with custom variables.

# Project workflow

1. To begin with, we will use the default VPC in the us-west-2 (Oregon) region to deploy all the necessary services.
2. Once we have the VPC/Subnet details, our first step will be to provision EFS storage using Terraform that spans all three availability zones. This will ensure that the Jenkins controller instance can mount the EFS filesystem from any of the three availability zones.
3. After setting up EFS storage, create an SSH key pair and upload it to the AWS Parameter Store. This enables secure connections between controller and agent nodes. Avoid storing system credentials locally for better security practices.
4. Next, use Packer and Ansible roles to build the controller and agent AMIs, including the necessary applications and configurations. After building the AMIs, deploy them using Terraform.
5. We will use Terraform to deploy the controller AMI in an auto-scaling group with minimum, maximum, and desired values set to 1. This configuration ensures we avoid running multiple instances of the Jenkins controller, which could cause inconsistencies in Jenkins files and configurations. Additionally, we will deploy an ALB with a target group pointing to the Jenkins auto-scaling group.
6. After deploying the Jenkins controller, we will use Terraform to deploy an agent server.
7. Lastly, we will validate the Jenkins controller and agent setup with the necessary configurations, ensuring that our Jenkins setup functions as expected.