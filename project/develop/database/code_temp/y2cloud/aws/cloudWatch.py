from .awsService import AwsService
import boto3

class CloudWatch(AwsService):
    
    def __init__(self) -> None:
        self.__name = "cloudwatch"


    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)



