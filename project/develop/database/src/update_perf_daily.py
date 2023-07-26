from customPerfDAO import CustomPerfDAO
from customPerfDO import CustomPerfDO
import boto3
import json
import yaml
import sys

sys.path.append("/home/zabbix/lib")
import y2cloud.aws as y2

INSTANCE_CLASS_PATH="/home/zabbix/data/instance_class.json"
ACCOUNT_PATH="/home/zabbix/config/account.yaml"
ZABBIX_ROLE="role-zabbix-monitoring"


def updatePef_ec2():
    dao = CustomPerfDAO()
    #dao.select("""select * from msp_custom_perf;""")
    dao.insertPerfDaily_ec2()
    dao.insertDiskUtilDaily()


def updatePef_rds(credentials, instanceTypeDict):
    awsFactory = y2.RdsFactory()
    rds = awsFactory.useService(credentials)

    dbInstances = rds.describeDbInstances()
    dao = CustomPerfDAO()
    
    # Get Metric Data
    logs = credentials.client('logs')
    
    for dbInstance in dbInstances:
        
        #a = CustomPerfDO()
        #dao.insertPerfDaily_rds(a)
        pass


def main():
    # 0. Update rds instnace's performance
    default_cred = boto3.session.Session(profile_name="default")
    sts = default_cred.client('sts')
    assumeRole_cred = None
    awsFactory : y2.AwsFactory = None

    ## 1. Insatnce Class 정보 가지고 오기
    with open(INSTANCE_CLASS_PATH, 'r') as jsonFile:
        jsonData = json.load(jsonFile)
    instanceTypeDict = json.loads(jsonData)

    ## 2. Get account list
    accountFile = {}
    accountList = []
    with open(ACCOUNT_PATH, encoding='UTF-8') as f:
        accountFile = yaml.load(f, Loader=yaml.FullLoader)

    for account in accountFile.keys():
        accountList.append(account)


    # Update performance logic
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

        assumeRole_cred = boto3.session.Session(
            aws_access_key_id = assumeRole['Credentials']['AccessKeyId'],
            aws_secret_access_key = assumeRole['Credentials']['SecretAccessKey'],
            aws_session_token = assumeRole['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )

        updatePef_rds(assumeRole_cred, instanceTypeDict)

    updatePef_ec2()


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()