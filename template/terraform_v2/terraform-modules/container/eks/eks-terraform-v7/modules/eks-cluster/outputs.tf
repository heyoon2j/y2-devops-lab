output "name" {
  value = aws_eks_cluster.this.name
}

output "endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_issuer" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}