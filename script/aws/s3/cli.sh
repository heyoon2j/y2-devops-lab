# List
aws s3 ls <S3URI or None>
aws s3 ls s3://<bucket>


# cp 
## --acl bucket-owner-full-control : 객체에 대하여 버킷 소유자에게 권한 제공
aws s3 cp <localPaht> <S3URI>

aws s3 cp . s3://my-bucket/path --exclude "*.txt" --include "*.jpg"
aws s3 cp . s3://my-bucket/path --acl bucket-owner-full-control


aws s3 rm s3://my-bucket/path --recursive


aws s3 mv test.txt s3://mybucket/test2.txt