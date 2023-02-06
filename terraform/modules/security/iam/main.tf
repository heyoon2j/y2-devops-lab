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

resource "aws_iam_role" "role-proj" {
    count = length(var.role)

    name = var.role[count.index]["name"]
    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    assume_role_policy = <<EOF
${var.role[count.index]["assume_role_policy"]}
    EOF
    #jsonencode(var.role[count.index]["assume_role_policy"])
    # tags = {
    #     tag-key = "tag-value"
    # }
}


resource "aws_iam_policy" "policy-user-proj" {
    count = length(var.user_policy)

    name        = var.user_policy[count.index]["name"] #"policy-${var.proj_name}-${var.proj_env}-${var.user_policy[count.index]["name"]}"
    path        = var.user_policy[count.index]["path"]
    description = var.user_policy[count.index]["description"]

    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = <<EOF
${var.user_policy[count.index]["json"]}
    EOF
    #jsonencode(var.user_policy[count.index]["json"])
}

resource "aws_iam_policy_attachment" "policy-attach-user-proj" {
    count = length(var.user_policy)

    name       = "${var.user_policy[count.index]["name"]}"
    roles      = var.user_policy[count.index]["attachment_roles"]
    users      = var.user_policy[count.index]["attachment_users"]
    groups     = var.user_policy[count.index]["attachment_groups"]
    policy_arn = aws_iam_policy.policy-user-proj[count.index].arn

    depends_on = [
        aws_iam_role.role-proj
    ]
}

data "aws_iam_policy" "policy-aws-proj" {
    count = length(var.aws_policy)

    arn = var.aws_policy[count.index]["arn"] #"arn:aws:iam::aws:policy/${}"
}


resource "aws_iam_policy_attachment" "policy-attach-aws-proj" {
    count = length(var.aws_policy)

    name       = "${var.aws_policy[count.index]["name"]}"
    roles      = var.aws_policy[count.index]["attachment_roles"]
    users      = var.aws_policy[count.index]["attachment_users"]
    groups     = var.aws_policy[count.index]["attachment_groups"]
    policy_arn = data.aws_iam_policy.policy-aws-proj[count.index].arn

    depends_on = [
        aws_iam_role.role-proj
    ]
}
