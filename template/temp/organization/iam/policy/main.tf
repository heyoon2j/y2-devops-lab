#############################################################################################
/* IAM Policy Configuration
1. Policy Custom 생성
2. Policy Boundary 생성
*/
#############################################################################################

resource "aws_iam_policy" "custom" {
    for_each = var.policy_custom

    name        = each.value["name"]
    path        = each.value["path"]
    description = each.value["description"]

    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = <<EOF
${each.value["policy"]}
    EOF
    #jsonencode(var.user_policy[count.index]["json"])
}

resource "aws_iam_policy" "boundary" {
    for_each = var.policy_boundary

    name        = each.value["name"]
    path        = each.value["path"]
    description = each.value["description"]

    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = <<EOF
${each.value["policy"]}
    EOF
    #jsonencode(var.user_policy[count.index]["json"])
}