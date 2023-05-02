# custom_perf DO
class CustomPerfDO():
    def __init__(self, hostName, collectDate, cpuAvg, cpuMax, memAvg, memMax):
        self.__hostName = hostName
        self.__collectDate = collectDate
        self.__cpuAvg = cpuAvg
        self.__cpuMax = cpuMax
        self.__memAvg = memAvg
        self.__memMax = memMax
    
    def __del__(self):
        del self.__hostName
        del self.__collectDate
        del self.__cpuAvg
        del self.__cpuMax
        del self.__memAvg
        del self.__memMax
    
    @property
    def hostName(self):
        return self.__hostName

    @hostName.setter
    def hostName(self, hostName):
        self.__hostName = hostName

    @property
    def collectDate(self):
        return self.__collectDate

    @collectDate.setter
    def collectDate(self, collectDate):
        self.__collectDate = collectDate 

    @property
    def cpuAvg(self):
        return self.__cpuAvg

    @cpuAvg.setter
    def cpuAvg(self, cpuAvg):
        self.__cpuAvg = cpuAvg

    @property
    def cpuMax(self):
        return self.__cpuMax

    @cpuMax.setter
    def cpuMax(self, cpuMax):
        self.__cpuMax = cpuMax

    @property
    def memAvg(self):
        return self.__memAvg

    @memAvg.setter
    def memAvg(self, memAvg):
        self.__memAvg = memAvg

    @property
    def memMax(self):
        return self.__memMax

    @memMax.setter
    def memMax(self, memMax):
        self.__memMax = memMax
