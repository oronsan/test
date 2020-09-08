resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
}

resource "aws_ecr_repository" "test" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

locals {
  azs = ["us-east-1a", "us-east-1b"]
  cidrs = ["10.0.0.0/24", "10.0.1.0/24"]
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.cidrs[count.index]
  availability_zone = local.azs[count.index]
  count = length(local.cidrs)
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "route_table_assoc" {
  subnet_id      = aws_subnet.subnet.*.id[count.index]
  route_table_id = aws_route_table.route_table.id
  count = length(aws_subnet.subnet.*.id)
}

resource "aws_route" "public-subnet-to-igw" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
