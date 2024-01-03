resource "aws_eks_cluster" "example" {
    name     = var.k8s_cluster.cluster_name
    role_arn = var.k8s_

    vpc_config {
        subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
    }

    # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
    # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
    depends_on = [
        aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
        aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
    ]
    }



resource "aws_eks_addon" "example" {
  cluster_name                = aws_eks_cluster.example.name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
}




output "endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.example.certificate_authority[0].data
}


resource "aws_eks_identity_provider_config" "example" {
  cluster_name = aws_eks_cluster.example.name

  oidc {
    client_id                     = "your client_id"
    identity_provider_config_name = "example"
    issuer_url                    = "your issuer_url"
  }
}


resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example"
  node_role_arn   = aws_iam_role.example.arn
  subnet_ids      = aws_subnet.example[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}
Ignoring Changes to Desired Size
You can utilize the generic Terraform resource lifecycle configuration block with ignore_changes to create an EKS Node Group with an initial size of running instances, then ignore any changes to that count caused externally (e.g., Application Autoscaling).

resource "aws_eks_node_group" "example" {
  # ... other configurations ...

  scaling_config {
    # Example: Create EKS Node Group with 2 instances to start
    desired_size = 2

    # ... other configurations ...
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}