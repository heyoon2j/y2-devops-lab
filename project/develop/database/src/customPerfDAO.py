from customPerfDO import CustomPerfDO
from psqlDbConnection import PsqlDbConnection
import re

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


    def insertDiskUtilDaily(self, query=None):
        try:
            conn = self.__datasource.getConnection()
            cur = conn.cursor()
            if query is not None:
                cur.execute(query)           
            else:
                cur.execute("""
                insert into msp_custom_perf (name, collect_date, disk_total, disk_used, disk_used_pct)
                    select h.name as name,
                        date_trunc('day', to_timestamp(hu.clock)) as collect_date,
                        (sum(case i.name when 'Total disk space on $1' then hu.value end)/1024/1024/1024)::integer as disk_total,
                        (sum(case i.name when 'Used disk space on $1' then hu.value end)/1024/1024/1024)::integer as disk_used,
                        100 * sum(case i.name when 'Used disk space on $1' then hu.value end) / sum(case i.name when 'Total disk space on $1' then hu.value end) as disk_used_pct
                    from hosts h
                        inner join items i on i.hostid = h.hostid
                            and i.name in ('Total disk space on $1', 'Used disk space on $1')
                        inner join history_uint hu on hu.itemid = i.itemid
                    where h.status = 0
                        and h.flags = 0
                        and hu.clock >= CAST(EXTRACT(epoch FROM DATE_TRUNC('DAY', NOW() - INTERVAL '1' DAY)) AS INTEGER)
                        and hu.clock < CAST(EXTRACT(epoch FROM DATE_TRUNC('DAY', NOW())) AS INTEGER)
                        -- and t.clock = extract(epoch from CURRENT_DATE - 1)::integer
                        -- and t.clock >= extract(epoch from to_timestamp('2023-04-01', 'YYYY-MM-DD'))::integer
                        -- and t.clock < extract(epoch from to_timestamp('2023-04-16', 'YYYY-MM-DD'))::integer
                    group by h.name, date_trunc('day', to_timestamp(hu.clock))
                on conflict (name, collect_date)
                do update set disk_total=EXCLUDED.disk_total, disk_used=EXCLUDED.disk_used, disk_used_pct=EXCLUDED.disk_used_pct
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


    def insertPerfDaily_ec2(self, query=None):
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
                insert into msp_custom_perf (name, collect_date, cpu_avg, cpu_max, mem_avg, mem_max)
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
    
    def insertPerfDaily_rds(self, cpDo, query=None):
        try:
            conn = self.__datasource.getConnection()
            cur = conn.cursor()
            if query is None:
                query = """insert into msp_custom_perf (name, collect_date, cpu_avg, cpu_max, mem_avg, mem_max, disk_total, disk_used, disk_used_pct)
                values ('{}', '{}', {}, {}, {}, {}, {}, {}, {})
                on conflict (name, collect_date)
                do update set cpu_avg=EXCLUDED.cpu_avg, cpu_max=EXCLUDED.cpu_max, mem_avg=EXCLUDED.mem_avg, mem_max=EXCLUDED.mem_max, disk_total=EXCLUDED.disk_total, disk_used=EXCLUDED.disk_used, disk_used_pct=EXCLUDED.disk_used_pct
                ;
                """.format(cpDo.hostName, cpDo.collectDate, cpDo.cpuAvg, cpDo.cpuMax, cpDo.memAvg, cpDo.memMax, cpDo.disk_total, cpDo.disk_used, cpDo.disk_used_pct)

            query = self.changeToNull(query)
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

    def changeToNull(self, query):
        query = re.sub("('None')|(None)", 'Null', query)
        return query