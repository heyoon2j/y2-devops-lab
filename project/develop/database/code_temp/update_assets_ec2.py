import boto3
import yaml
from CustomAssetsDAO import CustomAssetsDAO
from CustomAssetsDO import CustomAssetsDO
from y2cloud.aws import *


ASSETS_CONFIG_PATH="/home/zabbix/config/assets_meta.yaml"
ROLE_ARN_PATH="/home/zabbix/config/roleArn.yaml"

def main():

    # OU에서 계정 정보 가져오기
    # 파일 정보 가져오기
    roleArns = {}
    with open(ROLE_ARN_PATH, encoding='UTF-8') as f:
        roleArns = yaml.load(f, Loader=yaml.FullLoader)
    
    
    for roleArn in roleArns.values():
        # Assume Role 정보 가져오기
        session = boto3.session.Session(profile_name="default")
        sts_client = session.client('sts')
        assume_role = sts_client.assume_role(
            RoleArn = roleArn,
            RoleSessionName = "zabbixRole"
        )

        if assume_role is None:
            continue

        # Assume Role 정보를 가지고 Credential 설정
        assume_role_session = boto3.session.Session(
            aws_access_key_id = assume_role['Credentials']['AccessKeyId'],
            aws_secret_access_key = assume_role['Credentials']['SecretAccessKey'],
            aws_session_token = assume_role['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )

        awsFactory : AwsFactory = Ec2Factory()
        service : Ec2 = awsFactory.useService

        print(service.name)

        #client = assume_role_session.client(service.name)

        assets = list()
        instances = service.describe_instances()
        
        for instance in instances:
            print(instance["hostName"], instance["ipAddress"], instance["account"], instance["vCpu"], instance["memory"], instance["volume"])
            assets.append(CustomAssetsDO(hostName=instance["hostName"], ipAddress=instance["ipAddress"], account=instance["account"], instanceType=instance["instanceType"], vCpu=instance["vCpu"], memory=instance["memory"], volume=instance["volume"]))
 
        for a in assets:
            dao = CustomAssetsDAO()
            dao.select("""select * from custom_assets""")
            #dao.insertAssetEc2sDaliy(a)


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()
