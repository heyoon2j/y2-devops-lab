# custom_perf DO
class CustomPerfDO:
    def __init__(self, host_name, collect_date, cpu_avg, avg_max, mem_avg, mem_max):
        self.host_name = host_name
        self.collect_date = collect_date
        self.cpu_avg = cpu_avg
        self.cpu_max = cpu_max
        self.mem_avg = mem_avg
        self.mem_max = mem_max
    
    def __del__(self):
        del host_name
        del collect_date
        del cpu_avg
        del cpu_max
        del mem_avg
        del mem_max


## dbLib 
# Connection 
import psycopg2
import yaml

def getConnectionInfo(file):

    db_cfg = {}    
    with open(file, encoding='UTF-8') as f:
        cfg = yaml.load(f, Loader=yaml.FullLoader)

    db_cfg['host'] = cfg['host']
    db_cfg['dbname'] = cfg['dbname']    
    db_cfg['user'] = cfg['user']
    db_cfg['password'] = cfg['password']
    db_cfg['port'] = cfg['port']

    return db_cfg

def getConnection(host, port, dbname, user, password):
    try:
        conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, port=port)
    except Exception as e:
        print("[error] cannot connect to postgresql", e, sep="\n")
    else:
        return conn


def closeConnection(conn):
    try:
        conn.close()
    except Exception as e:
        print("[error] cannot close connection", e, sep="\n")       


def selectPerf(conn, query=None):
    try:
        cur = conn.cursor()
        if query is not None:
            cur.execute(query)
        else:
            cur.execute("""select h.name as host_name,
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
            ;""")

    except Exception as e:
        pass


def insertPerf(conn, query=None):
    try:
        cur = conn.cursor()
        if query is not None:
            cur.execute(query)
        else:
            cur.execute("""SELECT * FROM custom_perf;""")
            cur.execute("""insert into custom_perf(host_name, collect_date, cpu_avg, cpu_max, mem_util_avg, mem_util_max) 
            values ('abc', '2023-04-16', 3.0, 4.0, 5.0, 6.0);""") 
        conn.commit()

    except Exception as e:
        conn.rollback()
        print("[error] insert error", e, sep="\n")



## Main
import dbLib

def main():

    db_cfg = dbLib.getConnectionInfo('db_cfg.yaml') 

    # host="127.0.0.1"
    # port=5432
    # dbname="test"
    # user="postgres"
    # password=""

    host = db_cfg['host']
    port = db_cfg['port']
    dbname= db_cfg['dbname']
    user = db_cfg['user']
    password = db_cfg['password']    

    conn = dbLib.getConnection(host, port, dbname, user, password)
    print("exit")
    if conn is not None:
        dbLib.insertPerf(conn)
        dbLib.closeConnection(conn)
    

if __name__ == "__main__":
    main()


# CustomPerfLogic
