data "aws_subnets" "shared" {}
data "aws_security_group" "baseline" {}
data "aws_iam_role" "eks_cluster" {
  name = "temp-iam-dev-zootopia-eks-cluster-role"
}
