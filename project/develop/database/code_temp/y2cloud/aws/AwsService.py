from abc import ABC, abstractmethod

class AwsService(ABC):
    def __init__(self) -> None:
        self.__client = None

    @abstractmethod
    def applyCredentials(self, credentials):
        pass