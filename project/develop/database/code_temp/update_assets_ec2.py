import yaml
#from CustomAssetsDAO import CustomAssetsDAO
#from CustomAssetsDO import CustomAssetsDO
import y2cloud.aws as y2

ROLE_ARN_PATH="/home/zabbix/config/roleArn.yaml"

def main():
    default_cred = y2.AwsProvider.credentials(profile_name="default")
    assumeRole_cred : y2.AwsProvider = None
    awsFactory : y2.AwsFactory = None
    ec2 = None
    sts = None
    ou = None

    # OU에서 계정 정보 가져오기
    # 파일 정보 가져오기
    roleArns = {}
    with open(ROLE_ARN_PATH, encoding='UTF-8') as f:
        roleArns = yaml.load(f, Loader=yaml.FullLoader)
    """
    awsFactory = y2.OrganizationsFactory()
    ou = awsFactory.useService(default_cred)
    accountList = ou.getListAccounts()
    print(accountList)
    """
    # for roleArn in roleArns:
    for i in range(1):
    #for account in accountList:

        # Assume Role 정보 가져오기
        """
        awsFactory = y2.StsFactory()
        sts = awsFactory.useService(default_cred)
        assumeRole = sts.assume_role(
            RoleArn = roleArn,
            RoleSessionName = "zabbixRole"
        )

        if assumeRole is None:
            continue

        # Assume Role 정보를 가지고 Credential 설정
        assumeRole_cred = y2.AwsProvider.credentials(
            aws_access_key_id = assumeRole['Credentials']['AccessKeyId'],
            aws_secret_access_key = assumeRole['Credentials']['SecretAccessKey'],
            aws_session_token = assumeRole['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )
        """


        # EC2
        awsFactory = y2.Ec2Factory()
        ec2 = awsFactory.useService(assumeRole_cred)

        assets = list()
        instances = ec2.describe_instances()
        
        for instance in instances:
            print(instance['instanceId'], instance["hostName"], instance["ipAddress"], instance["account"], instance["instanceType"], instance["vCpu"], instance["memory"], instance["volume"])
            assets.append(CustomAssetsDO(hostName=instance["hostName"], ipAddress=instance["ipAddress"], account=instance["account"], instanceType=instance["instanceType"], vCpu=instance["vCpu"], memory=instance["memory"], volume=instance["volume"]))
 
        
        #for a in assets:
        #    dao = CustomAssetsDAO()
        #    dao.select("""select * from custom_assets""")
            #dao.insertAssetEc2sDaliy(a)
    

# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()


