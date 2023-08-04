from abc import ABC, abstractmethod
from .ec2 import Ec2
from .rds import Rds
from .sts import Sts
from .organizations import Organizations
from .cloudWatch import CloudWatch

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


class RdsFactory(AwsFactory):
    def create(self):
        return Rds()


class StsFactory(AwsFactory):
    def create(self):
        return Sts()

class OrganizationsFactory(AwsFactory):
    def create(self):
        return Organizations()

class CloudWatchFactory(AwsFactory):
    def create(self):
        return CloudWatch()