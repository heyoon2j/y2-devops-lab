import boto3
import yaml
import CustomAssetsDAO

session = boto3.Session(profile_name='dev')
dev_s3_client = session.client('s3')


# Profile 가져요기
client = boto3.client(
    's3',
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    aws_session_token=SESSION_TOKEN
)


# 각 계정 정보 저장
accounts = []

profiles = []

# 


# MetaData


def main():
    cfg_file = "assets_meta.yaml"

    for client in profiles:
        response = client.describe_instances()
        instances = list()
        assets = list()

        for reservation in response["Reservations"]:
            instances.add(reservation["Instances"])
        

        for instance in instances:
            with open(cfg_file, encoding='UTF-8') as f:
                cfg = yaml.load(f, Loader=yaml.FullLoader)
            hostName = instance["Tags"]
            ipAddress = instance["PrivateIpAddress"]
            accountName = instance["OwnerId"]
            vCpu = instance["InstanceType"]
            memory = instance["InstanceType"]
            volume = instance["BlockDeviceMappings"]

            assets.add(CustomAssetsDO(hostName, ipAddress, accountName, vCpu, memory, volume))


        for a in assets:
            dao = CustomAssetsDAO(a)
            conn = dao.getConnection()
            dao.insert(conn)

# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()