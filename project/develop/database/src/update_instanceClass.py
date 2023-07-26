import boto3
import json
import sys

sys.path.append("/home/zabbix/lib")
import y2cloud.aws as y2

INSTANCE_CLASS_PATH="/home/zabbix/data/instance_class.json"

def main():
    default_cred = boto3.session.Session(profile_name="default")

    awsFactory = y2.Ec2Factory()
    ec2 = awsFactory.useService(default_cred)
    instanceTypeDict = ec2.describe_instance_types()

    instanceTypeJson = json.dumps(instanceTypeDict)
    with open(INSTANCE_CLASS_PATH, 'w') as outfile:
        json.dump(instanceTypeJson, outfile)


if __name__ == "__main__":
    main()