from dbConnection import DbConnection
import psycopg2
from psycopg2 import pool
import yaml

DB_CONFIG_FILE = "/home/zabbix/config/db_cfg.yaml"

class PsqlDbConnection(DbConnection):
    def __init__(self):
        super().__init__()
        self.__connectionPool = None

        cfg = None
        with open(DB_CONFIG_FILE, encoding='UTF-8') as f:
            cfg = yaml.load(f, Loader=yaml.FullLoader)
            cfg = cfg["database"]["postgresql"]

        # db_cfg = dict()
        # db_cfg['host'] = cfg['host']
        # db_cfg['dbname'] = cfg['dbname']
        # db_cfg['user'] = cfg['user']
        # db_cfg['password'] = cfg['password']
        # db_cfg['port'] = cfg['port']
        
        try:
            self.__connectionPool = psycopg2.pool.SimpleConnectionPool(1, 2, host=cfg['host'], user = cfg['user'],
                                              password = cfg['password'],
                                              port = cfg['port'],
                                              database = cfg['dbname'])
        except Exception as e:
            print("[error] cannot connect to postgresql", e, sep="\n")


    def __del__(self):
        super().__del__()
        self.__connectionPool.closeall()

    def getConnection(self):
        try:
            #self.__conn = psycopg2.connect(host=db_cfg['host'], dbname=db_cfg['dbname'], user=db_cfg['user'], password=db_cfg['password'], port=db_cfg['port'])
            return self.__connectionPool.getconn()
        except Exception as e:
            print("[error] no connection count in pool", e, sep="\n")


    def close(self, conn):
        try:
            self.__connectionPool.putconn(conn)
        except Exception as e:
            print("[error] cannot close connection", e, sep="\n")  