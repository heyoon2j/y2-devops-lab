import CustomDAO
import CustomAssetsDO

class CustomAssetsDAO(CustomDAO):
    def __init__(self, csDo=None):
        self.__csDo = csDo

    def __del__(self):
        del self.__csDo

    def delete(self, conn, query):
        pass

    def update(self, conn, query):$$
        pass

    def select(self, conn, query=None):
        try:
            cur = conn.cursor()
            if query is not None:
                cur.execute(query)
            else:
                cur.execute("""select *
                from custom_assets ca
                    inner join host h on h. = ca.host_name
                ;""")

        except Exception as e:
            print("[error] select error", e, sep="\n")


    def insert(self, conn, query=None):
        try:
            cur = conn.cursor()
            if query is None:
                #cur.execute("""SELECT * FROM custom_perf;""")
                #cur.execute("""insert into custom_perf(host_name, collect_date, cpu_avg, cpu_max, mem_util_avg, mem_util_max) 
                #values ('abc', '2023-04-16', 3.0, 4.0, 5.0, 6.0);""")
                query = """insert into custom_assets (host_name, ip_address, account_name, vcpu, memory, volume, update_date)
                values ({}, {}, {}, {}, {}, {}, {}, CURRENT_DATE)
                on conflict (host_name)
                do update set
                ;
                """.format(self.__cpDo.hostName(), self.__cpDo.ipAddress(), self.__cpDo.accountName(), self.__cpDo.vCpu(),self.__cpDo.memory(), self.__cpDo.volume())
            cur.execute(query)
            conn.commit()

        except Exception as e:
            conn.rollback()
            print("[error] insert error", e, sep="\n")


######

class CustomPerfDO:
    def __init__(self, hostName, ipAddress, accountName, vCpu, memory, volume, updateDate):
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

####

class CustomPerfDO:
    def __init__(self, hostName, ipAddress, accountName, vCpu, memory, volume, updateDate):
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

####
from abc import ABC
import psycopg2
import yaml

class CustomDAO(ABC):

    def getConnection(cfg_file):
        db_cfg = {}    
        with open(cfg_file, encoding='UTF-8') as f:
            cfg = yaml.load(f, Loader=yaml.FullLoader)

            db_cfg['host'] = cfg['host']
            db_cfg['dbname'] = cfg['dbname']
            db_cfg['user'] = cfg['user']
            db_cfg['password'] = cfg['password']
            db_cfg['port'] = cfg['port']

        try:
            conn = psycopg2.connect(host=db_cfg['host'], dbname=db_cfg['dbname'], user=db_cfg['user'], password=db_cfg['password'], port=db_cfg['port'])
        except Exception as e:
            print("[error] cannot connect to postgresql", e, sep="\n")
        else:
            return conn

    def closeConnection(conn):
        try:
            conn.close()
        except Exception as e:
            print("[error] cannot close connection", e, sep="\n")

    # @abstractmethod
    # def insert(conn, query):
    #     pass

    # @abstractmethod
    # def delete(conn, query):
    #     pass

    # @abstractmethod
    # def update(conn, query):
    #     pass

    # @abstractmethod
    # def select(conn, query):
    #     pass


###
import CustomDAO
import CustomPerfDO

class CustomPerfDAO(CustomDAO):
    def __init__(self, cpDo=None):
        self.__cpDo = cpDo

    def __del__(self):
        del self.__cpDo

    def delete(conn, query):
        pass

    def update(conn, query):
        pass

    def select(conn, query=None):
        try:
            cur = conn.cursor()
            if query is  None:
                query = """select h.name as host_name,
                    to_char(to_timestamp(t.clock), 'YYYY-MM-DD') as collect_date,
                    avg(case i.name when 'CPU Utilization' then t.value_avg end) as cpu_avg,
                    min(case i.name when 'CPU Utilization' then t.value_max end) as cpu_max,
                    avg(case i.name when 'Memory utilization' then t.value_avg end) as mem_avg,
                    min(case i.name when 'Memory utilization' then t.value_max end) as mem_max,
                from host h
                    inner join items i on i.hostid = h.hostid
                    inner join trends t on t.itemid = i.itemid
                where h.status = 0
                    and h.flags = 0
                    and i.name in ('CPU Utilization', 'Memory utilization')
                    and t.clock = extract(epoch from CURRENT_DATE - 1)::integer
                group by h.name as host_name, to_char(to_timestamp(t.clock), 'YYYY-MM-DD')
                ;"""
            cur.execute(query)
        except Exception as e:
            print("[error] select error", e, sep="\n")


    def insert(conn, query=None):
        try:
            cur = conn.cursor()
            if query is not None:
                cur.execute(query)
            else:
                #cur.execute("""SELECT * FROM custom_perf;""")
                #cur.execute("""insert into custom_perf(host_name, collect_date, cpu_avg, cpu_max, mem_util_avg, mem_util_max) 
                #values ('abc', '2023-04-16', 3.0, 4.0, 5.0, 6.0);""")
                cur.execute("""insert into custom_perf (host_name, collect_date, cpu_avg, cpu_max, mem_avg, mem_max)
                    select h.name as host_name,
                        date_trunc('day', to_timestamp(t.clock)) as collect_date,
                        avg(case when i.name = 'CPU Utilization' then t.value_avg end) as cpu_avg,
                        min(case when i.name = 'CPU Utilization' then t.value_max end) as cpu_max,
                        avg(case when i.name = 'CPU Utilization' and date_part('dow', to_timestamp(t.clock)) in (0, 6) then t.value_avg end) as cpu_weekend,
                        avg(case when i.name = 'Memory utilization' then t.value_avg end) as mem_avg,
                        min(case when i.name = 'Memory utilization' then t.value_max end) as mem_max,
                        avg(case when i.name = 'Memory utilization' and date_part('dow', to_timestamp(t.clock)) in (0, 6) then t.value_avg end) as mem_weekend
                    from host h
                        inner join items i on i.hostid = h.hostid
                        inner join trends t on t.itemid = i.itemid
                    where h.status = 0
                        and h.flags = 0
                        and i.name in ('CPU Utilization', 'Memory utilization')
                        and t.clock >= extract(epoch from to_timestamp('2023-04-01', 'YYYY-MM-DD'))::integer
                        and t.clock < extract(epoch from to_timestamp('2023-04-16', 'YYYY-MM-DD'))::integer
                    group by h.name as host_name, date_trunc('day', to_timestamp(t.clock))
                on conflict (host_name, collect_date)
                do nothing
                ;
                """)
            conn.commit()

        except Exception as e:
            conn.rollback()
            print("[error] insert error", e, sep="\n")


####
# 
class CustomPerfDO():
    def __init__(self, hostName, collectDate, cpuAvg, cpuMax, cpuWeekend, memAvg, memMax, memWeekend):
        self.__hostName = hostName
        self.__collectDate = collectDate
        self.__cpuAvg = cpuAvg
        self.__cpuMax = cpuMax
        self.__cpuWeekend = cpuWeekend
        self.__memAvg = memAvg
        self.__memMax = memMax
        self.__memWeekend = memWeekend
    
    def __del__(self):
        del hostName
        del collectDate
        del cpuAvg
        del cpuMax
        del cpuWeekend
        del memAvg
        del memMax
        del memWeekend
    
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
    def cpuWeekend(self):
        return self.__cpuWeekend

    @cpuWeekend.setter
    def cpuWeekend(self, cpuWeekend):
        self.__cpuWeekend = cpuWeekend

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

    @property
    def memWeekend(self):
        return self.__memWeekend

    @memWeekend.setter
    def memWeekend(self, memWeekend):
        self.__memWeekend = memWeekend


####
import CustomAssetsDAO
import CustomPerfDAO


def main():
    conn = dbLib.getConnection(host, port, dbname, user, password)
    print("exit")
    if conn is not None:
        dbLib.insertPerf(conn)
        dbLib.closeConnection(conn)


# 매일 변경 분 업데이트
def main_asset():
    dao = CustomAssetsDAO()
    conn = dao.getConnection()
    dao.insert(conn)
    dao.cloasConnection()


# 매일 하루 평균 성능 데이터 입력
def main_perf():
    dao = CustomPerfDAO()
    conn = dao.getConnection()
    dao.insert(conn)
    dao.cloasConnection()


if __name__ == "__main__":
    main_perf()
    main_asset()
