from abc import ABC, abstractmethod
import AwsService
import Ec2

class AwsFactory(ABC):
    def useService(self) -> None:
        service = AwsService()
        return service.create()

    @abstractmethod
    def create(self):
        pass


class Ec2Factory(AwsFactory):
    def create(self):
        return Ec2()
