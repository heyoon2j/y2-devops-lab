output "s3" {
    description = "S3 Object Information"
    sensitive = true

    value = [
        for s3 in aws_s3_bucket.s3-proj:
            {
                "name" = s3.tags_all["Name"]
                "id" = s3.id
                "arn" = s3.arn
            }
    ]
}
