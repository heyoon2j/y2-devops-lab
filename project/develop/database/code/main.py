import CustomPerfDAO

def main():
    dao = CustomPerfDAO()
    conn = dao.getConnection()
    dao.insert(conn)


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()