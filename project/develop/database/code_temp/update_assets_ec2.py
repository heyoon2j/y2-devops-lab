import boto3
import yaml
from CustomAssetsDAO import CustomAssetsDAO
from CustomAssetsDO import CustomAssetsDO
from y2cloud.aws import *


ASSETS_CONFIG_PATH="/home/zabbix/config/assets_meta.yaml"
ROLE_ARN_PATH="/home/zabbix/config/roleArn.yaml"

def main():
    default_cred = AwsProvider.credentials(profile_name="default")
    assumeRole_cred : AwsProvider = None  

    awsFactory : AwsFactory = None
    ec2 = None
    sts = None
    ou = None

    # OU에서 계정 정보 가져오기
    # 파일 정보 가져오기
    roleArns = {}
    with open(ROLE_ARN_PATH, encoding='UTF-8') as f:
        roleArns = yaml.load(f, Loader=yaml.FullLoader)

    awsFactory = OrganizationsFactory()
    ou = awsFactory.useService(default_cred)
    accountList = ou.getListAccounts()
    print(accountList)

    for roleArn in roleArns:

    #for account in accountList:


        # Assume Role 정보 가져오기
        awsFactory = StsFactory()
        sts = awsFactory.useService(default_cred)
        assumeRole = sts.assume_role(
            RoleArn = roleArn,
            RoleSessionName = "zabbixRole"
        )

        if assumeRole is None:
            continue

        # Assume Role 정보를 가지고 Credential 설정
        assumeRole_cred = AwsProvider.credentials(
            aws_access_key_id = assumeRole['Credentials']['AccessKeyId'],
            aws_secret_access_key = assumeRole['Credentials']['SecretAccessKey'],
            aws_session_token = assumeRole['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )


        # EC2
        awsFactory = Ec2Factory()
        ec2 = awsFactory.useService(assumeRole_cred)

        assets = list()
        instances = ec2.describe_instances()
        
        for instance in instances:
            print(instance["hostName"], instance["ipAddress"], instance["account"], instance["vCpu"], instance["memory"], instance["volume"])
            assets.append(CustomAssetsDO(hostName=instance["hostName"], ipAddress=instance["ipAddress"], account=instance["account"], instanceType=instance["instanceType"], vCpu=instance["vCpu"], memory=instance["memory"], volume=instance["volume"]))
 
        
        #for a in assets:
        #    dao = CustomAssetsDAO()
        #    dao.select("""select * from custom_assets""")
            #dao.insertAssetEc2sDaliy(a)
    

# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()
