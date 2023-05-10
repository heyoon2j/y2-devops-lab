from CustomPerfDAO import CustomPerfDAO

def main():
    dao = CustomPerfDAO()
    dao.select("""select * from msp_custom_perf;""")
    #dao.insertPerfDaily()


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()