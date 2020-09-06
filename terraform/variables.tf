variable "vpc_cidr_block" { default = "10.0.0.0/16" }
variable "ecr_repo_name" { default = "test" }
variable "subnet_cidr" { default = "10.0.0.0/24" }
variable "min_size" { default = 1 }
variable "max_size" { default = 2 }
variable "desired_capacity" { default = 1 }
