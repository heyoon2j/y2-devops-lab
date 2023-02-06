output "nlb" {
    description = "VPC Information"
    sensitive = true

    value = [
        for nlb in aws_lb.nlb-proj:
            {
                "id" = nlb.id
                "name" = nlb.tags_all["Name"] 
            }
    ]
}
