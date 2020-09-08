#
# security group
#

resource "aws_security_group" "eks-node-sg" {
  name        = "eks-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "eks-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-node-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster" {
  description              = "Allow Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-https-ingress-cluster" {
  description              = "Allow Kubelets and pods to receive https communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
  to_port                  = 443
  type                     = "ingress"
}

# add rule to the security group of the eks cluster
resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks-node-sg.id
  to_port                  = 443
  type                     = "ingress"
}



#
# role
#

resource "aws_iam_role" "eks-node-role" {
  name = "eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "eks-instance-profile" {
  name = "eks-inst-profile"
  role = aws_iam_role.eks-node-role.name
}


locals {
  eks_node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "eks-node-policies-attachement" {
  policy_arn = element(local.eks_node_policies, count.index)
  role       = aws_iam_role.eks-node-role.name
  count = length(local.eks_node_policies)
}



#
# EC2
#

resource "aws_launch_configuration" "main" {
  name_prefix = format("eks-%s-", local.eks_name)

  iam_instance_profile = aws_iam_instance_profile.eks-instance-profile.name

  instance_type               = "t2.micro"
  image_id                    = "ami-02a815c648e3ac746"
  associate_public_ip_address = true # false
  key_name = "oron_own"
  security_groups             = [aws_security_group.eks-node-sg.id]

  user_data = base64encode(local.eks_node_userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "eks-${local.eks_name}"

  launch_configuration = aws_launch_configuration.main.id
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier  = aws_subnet.subnet.*.id

  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.eks_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "ecs-${local.eks_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster"
    value               = local.eks_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Automation"
    value               = "Terraform"
    propagate_at_launch = true
  }
}

