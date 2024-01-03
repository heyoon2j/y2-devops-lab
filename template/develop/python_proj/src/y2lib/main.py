from psqlDbConnection import PsqlDbConnection

def main():
    try:
        connPool = PsqlDbConnection().createConnPool()
        conn = connPool.getConnection()
        # cur = conn.cursor()
        # if query is not None:
        #     cur.execute(query)
        # else:
        #     cur.execute("""select *
        #     from msp_custom_assets ca
        #         inner join host h on h. = ca.host_name
        #     ;""")
    except Exception as e:
        print("[error] select error", e, sep="\n")
    finally:
        # if cur is not None:
        #     cur.close()
        if conn is not None:
            connPool.close(conn)


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()
