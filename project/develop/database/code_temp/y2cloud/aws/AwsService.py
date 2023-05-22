from abc import ABC, abstractmethod

class AwsService(ABC):
    def __init__(self) -> None:
        super().__init__()
        self.__provider = "test"
        self.__client = client

    def c(self):
        return self.__provider.client("ec2")

