provider "aws" {
  region = "us-west-2"
}

module "efs_module" {
  source = "../modules/efs"
  vpc_id     = "vpc-0c1daa67fb89fb29f"
  subnet_ids = ["subnet-0b01d37d289c7fd1d", "subnet-01395b76a07ba911b", "subnet-01e4aa3186984261c"]
}