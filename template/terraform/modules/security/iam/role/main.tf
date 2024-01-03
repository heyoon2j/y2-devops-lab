/*
1. Role 생성
2. ROle Attachment
*/

###############################################################

locals {
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Firewall policies
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_iam_role" "main" {
    name = var.name
    description = var.description

    path = var.path
    max_session_duration = var.max_session_duration
    force_detach_policies = var.force_detach_policies

    assume_role_policy = <<EOF
${var.assume_role_policy}
    EOF
    dynamic "inline_policy" {
        for_each = var.inline_policy
        content {
            name = inline_policy.value["name"]
            policy = <<EOF
${inline_policy.value["policy"]}
            EOF
        }
    }
    permissions_boundary = var.permissions_boundary
    tags = var.tags
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_iam_role_policy_attachment" "custom" {
    for_each = var.policy_arn_custom

    role       = aws_iam_role.main.name
    policy_arn = each.value

    depends_on = [
        aws_iam_role.main
    ]
}

resource "aws_iam_role_policy_attachment" "aws" {
    for_each = var.policy_arn_aws

    role       = aws_iam_role.main.name
    policy_arn = each.value

    depends_on = [
        aws_iam_role.main
    ]
}
