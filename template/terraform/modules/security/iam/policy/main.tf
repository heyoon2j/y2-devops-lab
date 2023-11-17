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



resource "aws_iam_policy" "policy_boundary" {
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



resource "aws_iam_policy" "policy_custom" {
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

