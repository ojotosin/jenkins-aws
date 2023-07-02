provider "aws" {
  region = "us-west-2"
}

module "asg-lb" {
  source        = "../modules/asg-lb"
  subnets       = ["subnet-0b01d37d289c7fd1d", "subnet-01395b76a07ba911b", "subnet-01e4aa3186984261c"]
  ami_id        = "ami-048f2aca461cc2f0c"
  instance_type = "t2.small"
  key_name      = "my-us-west-keypair"
  environment   = "dev"
  vpc_id        = "vpc-0c1daa67fb89fb29f"
}