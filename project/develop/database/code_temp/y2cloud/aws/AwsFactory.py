from abc import ABC, abstractmethod
from . import Ec2, Sts, Organizations

class AwsFactory(ABC):
    def useService(self, credentials) -> None:
        service = self.create()
        service.applyCredentials(credentials)
        return service

    @abstractmethod
    def create(self):
        pass


class Ec2Factory(AwsFactory):
    def create(self):
        return Ec2()


class StsFactory(AwsFactory):
    def create(self):
        return Sts()

class OrganizationsFactory(AwsFactory):
    def create(self):
        return Organizations()