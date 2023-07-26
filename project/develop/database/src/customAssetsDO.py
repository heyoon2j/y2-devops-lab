class CustomAssetsDO:
    def __init__(self, hostName, ipAddress, serviceType, instanceType, vCpu, memory, volume, account=None, updateDate=None):
        self.__hostName = hostName
        self.__ipAddress = ipAddress
        self.__account = account
        self.__serviceType = serviceType
        self.__instanceType = instanceType
        self.__vCpu = vCpu
        self.__memory = memory
        self.__volume = volume
        self.__updateDate = updateDate

    def __del__(self):
        del self.__hostName
        del self.__ipAddress
        del self.__account
        del self.__serviceType
        del self.__instanceType
        del self.__vCpu
        del self.__memory
        del self.__volume
        del self.__updateDate 

    @property
    def hostName(self):
        return self.__hostName

    @hostName.setter
    def hostName(self, hostName):
        self.__hostName = hostName

    @property
    def updateDate(self):
        return self.__updateDate

    @updateDate.setter
    def updateDate(self, updateDate):
        self.__updateDate = updateDate 

    @property
    def ipAddress(self):
        return self.__ipAddress

    @ipAddress.setter
    def ipAddress(self, ipAddress):
        self.__ipAddress = ipAddress

    @property
    def account(self):
        return self.__account

    @account.setter
    def account(self, account):
        self.__account = account

    @property
    def serviceType(self):
        return self.__serviceType
    
    @serviceType.setter
    def serviceType(self, serviceType):
        self.__serviceType = serviceType
    

    @property
    def instanceType(self):
        return self.__instanceType

    @instanceType.setter
    def instanceType(self, instanceType):
        self.__instanceType = instanceType

    @property
    def vCpu(self):
        return self.__vCpu

    @vCpu.setter
    def vCpu(self, vCpu):
        self.__vCpu = vCpu

    @property
    def memory(self):
        return self.__memory

    @memory.setter
    def memory(self, memory):
        self.__memory = memory

    @property
    def volume(self):
        return self.__volume

    @volume.setter
    def volume(self, volume):
        self.__volume = volume