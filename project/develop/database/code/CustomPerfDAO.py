from CustomPerfDO import CustomPerfDO
from PsqlDbConnection import PsqlDbConnection

class CustomPerfDAO():
    def __init__(self):
        self.__datasource = PsqlDbConnection()

    def __del__(self):
        pass

    def delete(self):
        pass

    def update(self):
        pass

    def select(self, query=None):
        try:
            conn = self.__datasource.getConnection()
            cur = conn.cursor()
            if query is  None:
                query = """
                select h.name as name,
                    date_trunc('day', to_timestamp(t.clock)) as collect_date,
                    avg(case when i.name = 'CPU Utilization' then t.value_avg end) as cpu_avg,
                    max(case when i.name = 'CPU Utilization' then t.value_max end) as cpu_max,
                    avg(case when i.name = 'Memory Utilization' then t.value_avg end) as mem_avg,
                    max(case when i.name = 'Memory Utilization' then t.value_max end) as mem_max
                from hosts h
                    inner join items i on i.hostid = h.hostid
                    inner join trends t on t.itemid = i.itemid
                where h.status = 0
                    and h.flags = 0
                    and i.name in ('CPU Utilization', 'Memory Utilization')
                    and t.clock >= CAST(EXTRACT FROM DATE_TRUNC('DAY', NOW() - INTERVAL '1' DAY)) AS INTEGER)
                    and t.clock < CAST(EXTRACT FROM DATE_TRUNC('DAY', NOW() - INTERVAL '2' DAY)) AS INTEGER)
                    -- and t.clock = extract(epoch from CURRENT_DATE - 1)::integer
                    -- and t.clock >= extract(epoch from to_timestamp('2023-04-01', 'YYYY-MM-DD'))::integer
                    -- and t.clock < extract(epoch from to_timestamp('2023-04-16', 'YYYY-MM-DD'))::integer
                group by h.name as name, date_trunc('day', to_timestamp(t.clock))
                ;
                """
            cur.execute(query)
        except Exception as e:
            print("[error] select error", e, sep="\n")
        finally:
            if cur is not None:
                cur.close()
            if conn is not None:
                self.__datasource.close(conn)


    def insertPerfDaily(self, query=None):
        try:
            conn = self.__datasource.getConnection()
            cur = conn.cursor()
            if query is not None:
                cur.execute(query)
            else:
                #cur.execute("""SELECT * FROM custom_perf;""")
                #cur.execute("""insert into custom_perf(host_name, collect_date, cpu_avg, cpu_max, mem_util_avg, mem_util_max) 
                #values ('abc', '2023-04-16', 3.0, 4.0, 5.0, 6.0);""")
                cur.execute("""
                insert into custom_perf (name, collect_date, cpu_avg, cpu_max, mem_avg, mem_max)
                    select h.name as name,
                        date_trunc('day', to_timestamp(t.clock)) as collect_date,
                        avg(case when i.name = 'CPU Utilization' then t.value_avg end) as cpu_avg,
                        min(case when i.name = 'CPU Utilization' then t.value_max end) as cpu_max,
                        avg(case when i.name = 'Memory Utilization' then t.value_avg end) as mem_avg,
                        min(case when i.name = 'Memory Utilization' then t.value_max end) as mem_max
                    from hosts h
                        inner join items i on i.hostid = h.hostid
                        inner join trends t on t.itemid = i.itemid
                    where h.status = 0
                        and h.flags = 0
                        and i.name in ('CPU Utilization', 'Memory Utilization')
                        and t.clock >= CAST(EXTRACT(epoch FROM DATE_TRUNC('DAY', NOW() - INTERVAL '1' DAY)) AS INTEGER)
                        and t.clock < CAST(EXTRACT(epoch FROM DATE_TRUNC('DAY', NOW())) AS INTEGER)
                        -- and t.clock = extract(epoch from CURRENT_DATE - 1)::integer
                        -- and t.clock >= extract(epoch from to_timestamp('2023-04-01', 'YYYY-MM-DD'))::integer
                        -- and t.clock < extract(epoch from to_timestamp('2023-04-16', 'YYYY-MM-DD'))::integer
                    group by h.name as name, date_trunc('day', to_timestamp(t.clock))
                on conflict (name, collect_date)
                do nothing
                ;
                """)
            conn.commit()
        except Exception as e:
            conn.rollback()
            print("[error] insert error", e, sep="\n")
        
        finally:
            if cur is not None:
                cur.close()
            if conn is not None:
                self.__datasource.close(conn)