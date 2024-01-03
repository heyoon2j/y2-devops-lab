output "endpoint" {
    value = aws_eks_cluster.control_plane.endpoint
}

output "kubeconfig_certificate_authority_data" {
    value = aws_eks_cluster.control_plane.certificate_authority[0].data
}
