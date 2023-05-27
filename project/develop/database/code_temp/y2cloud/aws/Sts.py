from .awsService import AwsService
import boto3

class Sts(AwsService):
    
    def __init__(self) -> None:
        self.__name = "sts"

    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)


    def assume_role(self, roleArn, roleSessionName):
        return self.__client.assume_role(
            RoleArn = roleArn,
            RoleSessionName = roleSessionName
        )

