/*
1. User
    1) User 생성
    2) User Policy 생성
    3) 생성한 User Policy Attachment
    4) Login Profile(Password 접속), Access Key(CLI), SSH Key

2. Group
    1) Group 생성
    2) Group Policy 설정
    3) 생성한 Group Policy Attachment
    4) Group Membership에 User 추가

3. Role
    1) Role 생성
    2) Role Policy 설정
    3) 생성한 Role Policy Attachment
*/

###############################################################

resource "aws_iam_role" "role_main" {
    name = var.role.name
    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    assume_role_policy = <<EOF
${var.role.assume_role_policy}
    EOF
    #jsonencode(var.role[count.index]["assume_role_policy"])
    # tags = {
    #     tag-key = "tag-value"
    # }
    dynamic "inline_policy" {
        for_each = var.role.inline_policy
        content {
            name = inline_policy.value["name"]
            policy = <<EOF
${inline_policy.value["policy"]}
            EOF
        }
    }

    #managed_policy_arns = var.role.managed_policy_arns
    
    permissions_boundary = var.role.permissions_boundary

    # depends_on = [
    #     aws_iam_role.role-proj
    # ]    
    tags = var.role.tags
}



###############################################################

resource "aws_iam_policy_attachment" "attach_policy_custom" {
    for_each = var.attach_policy_custom

    policy_arn = each.value
    
    name       = "${each.key}-attachment"
    roles      = [aws_iam_role.role_main.name]
    # users      = var.aws_policy[count.index]["attachment_users"]
    # groups     = var.aws_policy[count.index]["attachment_groups"]

    depends_on = [
        aws_iam_role.role_main
    ]
}

resource "aws_iam_policy_attachment" "attach_policy_aws" {
    for_each = var.attach_policy_aws

    policy_arn = each.value
    
    name       = "${each.key}-attachment"
    roles      = [aws_iam_role.role_main.name]
    # users      = var.aws_policy[count.index]["attachment_users"]
    # groups     = var.aws_policy[count.index]["attachment_groups"]

    depends_on = [
        aws_iam_role.role_main
    ]
}