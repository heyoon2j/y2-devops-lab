output "efs" {
    description = "EFS Information"
    sensitive = true

    value = [
        for efs in aws_efs_file_system.efs-proj:
            {
                "name" = efs.tags_all["Name"]
                "id" = efs.id
            }
    ]
}
