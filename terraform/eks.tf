resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_eks_cluster" "eks" {
  name     = local.eks_name
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks-cluster-sg.id]
    subnet_ids = aws_subnet.subnet.*.id

    endpoint_private_access = true
    endpoint_public_access = true
  }
}

#
# security group
#

resource "aws_security_group" "eks-cluster-sg" {
  name        = "eks-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster"
  }
}

#
# userdata
#
locals {
eks_name = "test"
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
  eks_node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint "${aws_eks_cluster.eks.endpoint}" \
--b64-cluster-ca "${aws_eks_cluster.eks.certificate_authority.0.data}" "${local.eks_name}"
USERDATA
}

