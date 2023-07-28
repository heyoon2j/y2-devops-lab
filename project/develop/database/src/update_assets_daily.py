import yaml
import boto3
import json
import sys
from customAssetsDAO import CustomAssetsDAO
from customAssetsDO import CustomAssetsDO

sys.path.append("/home/zabbix/lib")
import y2cloud.aws as y2

ACCOUNT_PATH="/home/zabbix/config/account.yaml"
INSTANCE_CLASS_PATH="/home/zabbix/data/instance_class.json"
ZABBIX_ROLE="role-zabbix-monitoring"


def updateAsset_ec2(credentials):
    # EC2
    awsFactory = y2.Ec2Factory()
    ec2 = awsFactory.useService(credentials)

    assets = list()
    instances = ec2.describe_instances()
    
    for instance in instances:
        print(instance['instanceId'], instance["hostName"], instance["ipAddress"], instance["account"], ec2.name, instance["instanceType"], instance["vCpu"], instance["memory"], instance["volume"])
        assets.append(CustomAssetsDO(hostName=instance["hostName"], ipAddress=instance["ipAddress"], account=instance["account"], serviceType=ec2.name, instanceType=instance["instanceType"], vCpu=instance["vCpu"], memory=instance["memory"], volume=instance["volume"]))
    
    dao = CustomAssetsDAO()
    for a in assets:
        dao.insertAssetsDaily(a)
    
        
def updateAsset_rds(credentials, instanceTypeDict):
    awsFactory = y2.RdsFactory()
    rds = awsFactory.useService(credentials)

    assets = list()
    dbInstances = rds.describeDbInstances()

    for dbInstance in dbInstances:
        instanceType = dbInstance["dbInstanceClass"].replace('db.','') 
        print(dbInstance['dbInstanceId'], rds.name, dbInstance["dbInstanceClass"], dbInstance["az"], dbInstance["storageSize"], instanceTypeDict[instanceType]['vCpu'], instanceTypeDict[instanceType]['mem']) 

        assets.append(CustomAssetsDO(hostName=dbInstance['dbInstanceId'],
         ipAddress=dbInstance["az"], 
         #account=dbInstance["account"], 
         serviceType=rds.name,
         instanceType=dbInstance["dbInstanceClass"], 
         vCpu=instanceTypeDict[instanceType]['vCpu'],
         memory=instanceTypeDict[instanceType]['mem'],
         volume=dbInstance["storageSize"]))

    dao = CustomAssetsDAO()
    for a in assets:
        dao.insertAssetsDaily(a)
    


def main():
    # 0. 기본 설정 값 가져오기
    default_cred = boto3.session.Session(profile_name="default")
    sts = default_cred.client('sts')
    assumeRole_cred = None
    awsFactory : y2.AwsFactory = None

    # 1. Get instnace Class
    with open(INSTANCE_CLASS_PATH, 'r') as jsonFile:
        jsonData = json.load(jsonFile)    
    instanceTypeDict = json.loads(jsonData)

    # 2. Get account list
    accountFile = {}
    accountList = []
    with open(ACCOUNT_PATH, encoding='UTF-8') as f:
        accountFile = yaml.load(f, Loader=yaml.FullLoader)

    for account in accountFile.keys():
        accountList.append(account)


    # Update assets logic
    for account in accountList:
        roleArn = 'arn:aws:iam::{}:role/{}'.format(account, ZABBIX_ROLE)
        print(roleArn)

        # Assume Role 정보 가져오기
        assumeRole = sts.assume_role(
            RoleArn = roleArn,
            RoleSessionName = "zabbixRole"
        )

        if assumeRole is None:
            continue

        # Assume Role 정보를 가지고 Credential 설정
        assumeRole_cred = boto3.session.Session(
            aws_access_key_id = assumeRole['Credentials']['AccessKeyId'],
            aws_secret_access_key = assumeRole['Credentials']['SecretAccessKey'],
            aws_session_token = assumeRole['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )

        updateAsset_ec2(assumeRole_cred)
        updateAsset_rds(assumeRole_cred, instanceTypeDict)


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()
