from .AwsService import AwsService
import boto3

class Organizations(AwsService):
    
    def __init__(self) -> None:
        self.__name = "ec2"


    def applyCredentials(self, credentials):
        self.__client = credentials.self.__client(self.__name)


    def getListAccounts(self):
        accountList = list()
        paginator = self.__client.get_paginator('list_accounts')
        for account in paginator['Accounts']:
            accountList.appned(account['Id'])
        return accountList


    def describe_volumes(self, **options):
        client = self.__credentials.client('ec2')
        response = client.describe_volumes(VolumeIds=options["VolumeIds"])

        # Customizing
        volume = 0
        for v in response["Volumes"]:
            volume += v["Size"]         

        return volume