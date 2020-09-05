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

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr

  availability_zone = "us-east-1a"
}

resource "aws_ecs_cluster" "ecs" {
  name = "test-apps"
  capacity_providers = ["FARGATE_SPOT"]
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.nginx.arn

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  network_configuration {
    subnets = aws_subnet.subnet.*.id
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

resource "aws_ecs_task_definition" "nginx" {
  family                = "nginx"
  container_definitions = file("../task-definition.json")
  network_mode = "awsvpc"
}
