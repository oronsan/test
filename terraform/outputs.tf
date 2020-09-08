locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-node-role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
  name: ${local.eks_name}
contexts:
- context:
    cluster: ${local.eks_name}
    user: ${local.eks_name}
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: ${local.eks_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
      - eks
      - get-token
      - --cluster-name
      - ${local.eks_name}
KUBECONFIG
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}
