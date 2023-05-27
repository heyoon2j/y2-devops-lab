import boto3

class AwsProvider:
    # Session / Client / Resource
    def __init__(self):
        pass

    @staticmethod
    def credentials(profile_name=None, region_name=None, accessKeyId= None, secretAcessKey=None, sessionToken=None):
        session = None
        if profile_name is not None:
            session = boto3.Session(profile_name=profile_name)

        elif accessKeyId is not None:
            session = boto3.Session(
                aws_access_key_id=accessKeyId,
                aws_secret_access_key=secretAcessKey,
                aws_session_token=sessionToken,
                region_name = region_name
            )
        else:
            session = boto3.Session(region_name=region_name)

        return session

