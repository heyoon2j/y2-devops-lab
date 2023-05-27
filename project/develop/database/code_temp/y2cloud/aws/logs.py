from .awsService import AwsService
import boto3

class Logs(AwsService):
    
    def __init__(self) -> None:
        self.__name = "logs"


    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)

