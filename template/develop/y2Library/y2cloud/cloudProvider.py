from abc import ABC, abstractmethod

class CloudProvider(ABC):
    @abstractmethod
    def credentials():
        pass

