provider "aws" {
    default_tags {
        tags = {
            Environment = "Test"
            Name = "Provider Tag"
        }
    }
}