import CustomDAO
import CustomPerfDO

class CustomPerfDAO(CustomDAO):
    def __init__(self, cpDo=None):
        self.__cpDo = cpDo

    def __del__(self):
        del self.__cpDo

    def delete(self, conn, query):
        pass

    def update(self,conn, query):
        pass

    def select(self, conn, query=None):
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


    def insert(self,conn, query=None):
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
        
        finally:
            self.closeConnection(conn)