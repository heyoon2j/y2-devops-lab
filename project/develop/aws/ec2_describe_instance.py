import boto3
import yaml
from CustomAssetsDAO import CustomAssetsDAO
from CustomAssetsDO import CustomAssetsDO


ASSETS_CONFIG_PATH="../config/assets_meta.yaml"
ROLE_ARN_PATH="../config/roleArn.yaml"


def main():

    session = boto3.session.Session(profile_name="default")
    client = session.client('ec2')

    response = client.describe_instance_types()
    instanceTypes = response["InstanceTypes"]
    instanceTypeDict = {}

    while "NextToken" in response:
        response = client.describe_instance_types(NextToken=response["NextToken"])
        instanceTypes.extend(response["InstanceTypes"])

    for it in instanceTypes:
        instanceTypeDict[it["InstanceType"]] = {"vCpu": it["VCpuInfo"]["DefaultVCpus"], "mem": int(it["MemoryInfo"]["SizeInMiB"]/1024)}


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
    
        # Assume Role 정보를 가지고 Credential 설정
        assume_role_session = boto3.session.Session(
            aws_access_key_id = assume_role['Credentials']['AccessKeyId'],
            aws_secret_access_key = assume_role['Credentials']['SecretAccessKey'],
            aws_session_token = assume_role['Credentials']['SessionToken'],
            region_name = "ap-northeast-2"
        )


        service = "ec2"
        client = assume_role_session.client(service)

        response = client.describe_instances()
        reservations = response["Reservations"]
        assets = list()

        while "NextToken" in response:
            response = client.describe_instances(NextToken=response["NextToken"])
            reservations.extend(response["Reservations"])


        for reservation in reservations:
            for instance in reservation["Instances"]:      
                hostName = None
                if "Tags" in instance:
                    ec2_tag = {}
                    for tag in instance["Tags"]:
                        ec2_tag[tag["Key"]] = tag["Value"]

                    if "Name" in ec2_tag:
                        hostName = ec2_tag["Name"]

                ipAddress = instance["PrivateIpAddress"]


                accountName = reservation["OwnerId"]


                vCpu = instanceTypeDict[instance["InstanceType"]]["vCpu"]
                memory = instanceTypeDict[instance["InstanceType"]]["mem"]
                
                volume = 0
                volumeIds = list()
                for ebs in instance["BlockDeviceMappings"]:
                    volumeIds.append(ebs["Ebs"]["VolumeId"])
                ebs_response = client.describe_volumes(VolumeIds=volumeIds)

                for v in ebs_response["Volumes"]:
                    volume += v["Size"]

                print(hostName, ipAddress, accountName, vCpu, memory, volume)

                assets.append(CustomAssetsDO(hostName=hostName, ipAddress=ipAddress, accountName=accountName, vCpu=vCpu, memory=memory, volume=volume))


        for a in assets:
            dao = CustomAssetsDAO(a)
            conn = dao.getConnection()
            dao.insert(conn)

# 매일 하루 평균 성능 데이터 입력
if __name__ == "__main__":
    main()


# aws ec2 describe-instance-types --query 'InstanceTypes[*].{instanceType: InstanceType, vCpu: VCpuInfo.DefaultVCpus, mem: MemoryInfo.SizeInMiB}'

