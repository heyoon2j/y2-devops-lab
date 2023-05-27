from .awsService import AwsService
import boto3

class Organizations(AwsService):
    
    def __init__(self) -> None:
        self.__name = "organizations"


    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)


    def getListAccounts(self):
        accountList = list()
        paginator = self.__client.get_paginator('list_accounts')
        page_interator = paginator.paginate()

        for page in page_interator:
            accountList.appned(page['Accounts']['Id'])

        """
        for account in paginator['Accounts']:
            accountList.appned(account['Id'])
        """
        return accountList


    def describe_volumes(self, **options):
        client = self.__credentials.client('ec2')
        response = client.describe_volumes(VolumeIds=options["VolumeIds"])

        # Customizing
        volume = 0
        for v in response["Volumes"]:
            volume += v["Size"]         

        return volume