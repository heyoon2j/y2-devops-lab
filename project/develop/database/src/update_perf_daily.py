from customPerfDAO import CustomPerfDAO
from customPerfDO import CustomPerfDO
import boto3
import json
import yaml
import sys
from datetime import datetime, date, timedelta

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

    performs = list()
    dbInstances = rds.describeDbInstances()

    
    # Get Metric Data
    awsFactory = y2.CloudWatchFactory()
    cw = awsFactory.useService(credentials)


    for dbInstance in dbInstances:
        dbInstanceName = dbInstance["dbInstanceId"]
        instanceType = dbInstance["dbInstanceClass"].replace('db.','')
        dbInstanceMem = instanceTypeDict[instanceType]['mem']

        yesterday = date.today() - timedelta(days = 1)

        cpuUtil = cw.get_metric_statistics_daily(options=
            {
                'Namespace': 'AWS/RDS',
                'MetricName' : 'CPUUtilization',
                'Dimensions' : [
                    {
                        'Name': 'DBInstanceIdentifier',
                        'Value': dbInstanceName
                    }
                ],
                'StartTime': datetime(yesterday.year, yesterday.month, yesterday.day, hour=0, minute=0, second=0, microsecond=0),
                'EndTime' : datetime(yesterday.year, yesterday.month, yesterday.day, hour=23, minute=59, second=59, microsecond=999),
                'Period' : 86400,
                'Statistics' : [
                    'Average','Maximum', 'Minimum'
                ]
            }
        )

        freeMem = cw.get_metric_statistics_daily(options= 
            {
                'Namespace': 'AWS/RDS',
                'MetricName' : 'FreeableMemory',
                'Dimensions' : [
                    {
                        'Name': 'DBInstanceIdentifier',
                        'Value': dbInstanceName
                    },
                ],
                'StartTime': datetime(yesterday.year, yesterday.month, yesterday.day, hour=0, minute=0, second=0, microsecond=0),
                'EndTime' : datetime(yesterday.year, yesterday.month, yesterday.day, hour=23, minute=59, second=59, microsecond=999),
                'Period' : 86400,
                'Statistics' : [
                    'Average','Maximum', 'Minimum'
                ]
            }
        )

        performs.append(CustomPerfDO(
            hostName=dbInstanceName,
            collectDate=datetime(yesterday.year, yesterday.month, yesterday.day),
            cpuAvg=cpuUtil[0],
            cpuMax=cpuUtil[1],
            memAvg=round((dbInstanceMem-freeMem[0])/dbInstanceMem*100,2),
            memMax=round((dbInstanceMem-freeMem[2])/dbInstanceMem*100,2),
            disk_total=None,
            disk_used=None,
            disk_used_pct=None))

    #dao = CustomPerfDAO()
    for p in performs:
        print(p.hostName, p.collectDate, p.cpuAvg, p.cpuMax, p.memAvg, p.memMax, p.disk_total, p.disk_used, p.disk_used_pct)
        #dao.insertPerfDaily_rds(p)
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
    print("===================================")


# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()