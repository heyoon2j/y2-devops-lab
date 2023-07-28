from .awsService import AwsService
import boto3

class Organizations(AwsService):
    
    def __init__(self) -> None:
        super().__init__("organizations")

    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)


    def getListAccounts(self):
        accountList = list()
        
        response = self._client.list_accounts()
        accountList.extend(response['Accounts'])

        while 'NextToken' in response:
            response = self._client.list_accounts(NextToken=response['NextToken'])
            accountList.extend(response['Accounts'])
        
        return accountList

