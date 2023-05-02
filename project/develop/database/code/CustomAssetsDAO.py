from CustomAssetsDO import CustomAssetsDO
from PsqlDbConnection import PsqlDbConnection

class CustomAssetsDAO():
    def __init__(self):
        self.__datasource = PsqlDbConnection()

    def __del__(self):
        del self.__cfg_file

    def delete(self):
        pass

    def update(self):
        pass

    def select(self, query=None):
        try:
            conn = self.__datasource.getConnection()
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
        finally:
            if cur is not None:
                cur.close()
            if conn is not None:
                self.__datasource.close(conn)


    def insertAssetsEc2Daliy(self, caDo, query=None):
        try:
            conn = self.__datasource.getConnection()
            cur = conn.cursor()
            if query is None:
                #cur.execute("""SELECT * FROM custom_perf;""")
                #cur.execute("""insert into custom_perf(host_name, collect_date, cpu_avg, cpu_max, mem_util_avg, mem_util_max) 
                #values ('abc', '2023-04-16', 3.0, 4.0, 5.0, 6.0);""")
                query = """insert into custom_assets (name, ip_address, account_name, vcpu, memory, volume, update_date)
                values ('{}', '{}', '{}', {}, {}, {}, {}, CURRENT_DATE)
                on conflict (name)
                do update set ('{}', '{}', '{}', {}, {}, {}, {}, CURRENT_DATE)
                ;
                """.format(caDo.hostName, caDo.ipAddress, caDo.accountName, caDo.vCpu,caDo.memory, caDo.volume)
            cur.execute(query)
            conn.commit()

        except Exception as e:
            conn.rollback()
            print("[error] insert error", e, sep="\n")
        
        finally:
            if cur is not None:
                cur.close()
            if conn is not None:
                self.__datasource.close(conn)


#insert into msp_custom_assets (name, ip_address, account_name, vcpu, memory, volume, update_date) values ('test123', '1.1.1.1', '123asdrf', 3, 4, 5, CURRENT_DATE) on conflict (name) do update set;