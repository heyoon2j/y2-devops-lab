import boto3

class AwsProvider:
    # Session / Client / Resource
    def __init__(self):
        pass

    def credentials(self, profile=None, region=None, accessKeyId= None, secretAcessKey=None, sessionToken=None):
        session = None
        if profile is not None:
            session = boto3.Session(profile_name=profile)

        elif accessKeyId is not None:
            session = boto3.Session(
                aws_access_key_id=accessKeyId,
                aws_secret_access_key=secretAcessKey,
                aws_session_token=sessionToken,
                region_name = region
            )
        else:
            session = boto3.Session()
        
        return session

