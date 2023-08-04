from abc import ABC, abstractmethod

class AwsService(ABC):
    def __init__(self, name=None) -> None:
        self._client = None
        self.__name = name

    def applyCredentials(self, credentials):
        self._client = credentials.client(self.__name)

    @property
    def name(self):
        return self.__name
    
    @name.setter
    def name(self, name):
        self.__name = name
        