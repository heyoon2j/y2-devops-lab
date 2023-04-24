
class CustomAssetsDO:
    def __init__(self, hostName, ipAddress, accountName, vCpu, memory, volume, updateDate=None):
        self.__hostName = hostName
        self.__ipAddress = ipAddress
        self.__accountName = accountName
        self.__vCpu = vCpu
        self.__memory = memory
        self.__volume = volume
        self.__updateDate = updateDate

    def __del__(self):
        del hostName
        del ipAddress
        del accountName
        del vCpu
        del memory
        del volume
        del updateDate 

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
    def accountName(self):
        return self.__accountName

    @accountName.setter
    def accountName(self, accountName):
        self.__accountName = accountName

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