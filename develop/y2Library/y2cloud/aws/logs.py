from .awsService import AwsService
import boto3

class Logs(AwsService):

    def __init__(self) -> None:
        super().__init__("logs")

