from dbConnection import DbConnection
import psycopg2
from psycopg2 import pool

DB_CONFIG_FILE = "/home/zabbix/config/db_cfg.yaml"

class PsqlDbConnection(DbConnection):
    def __init__(self):
        super().__init__()
        self.__connPool = None


    def createConnPool(self, connInfo):       
        try:
            self.__connPool = psycopg2.pool.SimpleConnectionPool(1, 2, host=connInfo['host'], user = connInfo['user'],
                                              password = connInfo['password'],
                                              port = connInfo['port'],
                                              database = connInfo['dbname'])
            print("[info] Create connection pool successfully(postgresql).", ps2e, sep="\n")

        except psycopg2.DatabaseError as ps2e:
            print("[error] Cannot create connection pool(postgresql).", ps2e, sep="\n")

        except Exception as e:
            print("[error] Need to debug.", e, sep="\n")


    def __del__(self):
        super().__del__()
        self.__connPool.closeall()

    def getConn(self):
        try:
            #self.__conn = psycopg2.connect(host=db_cfg['host'], dbname=db_cfg['dbname'], user=db_cfg['user'], password=db_cfg['password'], port=db_cfg['port'])
            return self.__connPool.getconn()
        except Exception as e:
            print("[error] no connection count in pool", e, sep="\n")


    def closeConn(self, conn):
        try:
            self.__connPool.putconn(conn)
        except Exception as e:
            print("[error] cannot close connection", e, sep="\n")  