variable "s3" {
    description = "S3 Object Information"
    type = list(object({
        name = string
        tags = map(string)
        block_public_acls       = bool
        ignore_public_acls      = bool
        block_public_policy     = bool
        restrict_public_buckets = bool

        object_ownership = string
        
        bucket_key_enabled = bool
        sse_algorithm = string
        kms_id = string
    }))
}

variable "s3_bucket_policy" {
    description = "S3 Object's bucket policy Information"
    type = list(object({
        name = string
        bucket_policy = string 
    }))
}