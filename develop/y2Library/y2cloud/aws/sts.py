from .awsService import AwsService
import boto3

class Sts(AwsService):
    """
    (deprecated)
    """    
    def __init__(self) -> None:
        self.__name = "sts"

    def assume_role(self, roleArn, roleSessionName):
        return self._client.assume_role(
            RoleArn = roleArn,
            RoleSessionName = roleSessionName
        )

