from abc import ABC
import psycopg2
import yaml

class CustomDAO(ABC):

    def getConnection(self, cfg_file):
        db_cfg = {}    
        with open(cfg_file, encoding='UTF-8') as f:
            cfg = yaml.load(f, Loader=yaml.FullLoader)
            cfg = cfg["database"]["postgresql"]
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

    def closeConnection(self, conn):
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
