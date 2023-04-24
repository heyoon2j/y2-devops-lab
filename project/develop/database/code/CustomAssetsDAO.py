import CustomDAO
import CustomAssetsDO

class CustomAssetsDAO(CustomDAO):
    def __init__(self, caDo=None):
        self.__caDo = caDo

    def __del__(self):
        del self.__caDo

    def delete(self, conn, query):
        pass

    def update(self, conn, query):
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
                """.format(self.__caDo.hostName(), self.__caDo.ipAddress(), self.__caDo.accountName(), self.__caDo.vCpu(),self.__caDo.memory(), self.__caDo.volume())
            cur.execute(query)
            conn.commit()

        except Exception as e:
            conn.rollback()
            print("[error] insert error", e, sep="\n")
        
        finally:
            self.closeConnection(conn)