import boto3

def event():
    response = client.get_object(
        Bucket='string',
        IfMatch='string',
        IfModifiedSince=datetime(2015, 1, 1),
        IfNoneMatch='string',
        IfUnmodifiedSince=datetime(2015, 1, 1),
        Key='string',
        Range='string',
        ResponseCacheControl='string',
        ResponseContentDisposition='string',
        ResponseContentEncoding='string',
        ResponseContentLanguage='string',
        ResponseContentType='string',
        ResponseExpires=datetime(2015, 1, 1),
        VersionId='string',
        SSECustomerAlgorithm='string',
        SSECustomerKey='string',
        RequestPayer='requester',
        PartNumber=123,
        ExpectedBucketOwner='string',
        ChecksumMode='ENABLED'
    )