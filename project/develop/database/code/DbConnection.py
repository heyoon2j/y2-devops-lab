from abc import ABC, abstractmethod

class DbConnection(ABC):
    def __init__(self):
        self.__conn = None

    def __del__(self):
        pass

    @abstractmethod
    def getConnection(self):
        pass

    @abstractmethod
    def close(self):
        pass
