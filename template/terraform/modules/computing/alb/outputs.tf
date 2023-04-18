output "alb" {
    description = "VPC Information"
    sensitive = true

    value = [
        for alb in aws_lb.alb-proj:
            {
                "id" = alb.id
                "name" = alb.tags_all["Name"] 
            }
    ]
}
