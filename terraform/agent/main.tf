provider "aws" {
  region = "us-west-2"
}

module "ec2_instance" {
  source = "../modules/ec2"

  instance_name      = "jenkins-agent"
  ami_id             = "ami-0c4b7ac6375736e78"
  instance_type      = "t2.small"
  key_name           = "my-us-west-keypair"
  subnet_ids         = ["subnet-0b01d37d289c7fd1d", "subnet-01395b76a07ba911b", "subnet-01e4aa3186984261c"]
  instance_count     = 1
}