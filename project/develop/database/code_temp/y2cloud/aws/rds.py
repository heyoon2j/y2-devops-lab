from .awsService import AwsService
import boto3

class Rds(AwsService):
    
    def __init__(self) -> None:
        self.__name = "rds"


    def applyCredentials(self, credentials):
        self.__client = credentials.client(self.__name)


    def describeInstances(self, **options):
        reservations = list()
        dbInstances = list()



        response = self.__client.describe_instances()
        reservations = response["Reservations"]

        while "NextToken" in response:
            response = self.__client.describe_instances(NextToken=response["NextToken"])
            reservations.extend(response["Reservations"])





        ##################################################
        # Customizing
        instanceTypeDict = self.describe_instance_types()

        for reservation in reservations:
            for instance in reservation["Instances"]:
                #instanceId = instance["InstanceId"]
                hostName = None
                if "Tags" in instance:
                    ec2_tag = {}
                    for tag in instance["Tags"]:
                        ec2_tag[tag["Key"]] = tag["Value"]

                    if "Name" in ec2_tag:
                        hostName = ec2_tag["Name"]

                #ipAddress = instance["PrivateIpAddress"]
                #account = reservation["OwnerId"]
                #instanceType = instance["InstanceType"]                
                #vCpu = instanceTypeDict[instance["InstanceType"]]["vCpu"]
                #memory = instanceTypeDict[instance["InstanceType"]]["mem"]

                volumeIds = list()
                for ebs in instance["BlockDeviceMappings"]:
                    volumeIds.append(ebs["Ebs"]["VolumeId"])
                # volume = self.describe_volumes({"VolumeIds" : volumeIds})                 

                dbInstances.append({
                    "instanceId" : instance["InstanceId"],
                    "hostName" : hostName,
                    "ipAddress" :instance["PrivateIpAddress"],
                    "account" : reservation["OwnerId"],
                    "instanceType" : instance["InstanceType"],           
                    "vCpu" : instanceTypeDict[instance["InstanceType"]]["vCpu"],
                    "memory" : instanceTypeDict[instance["InstanceType"]]["mem"],
                    "volume" : self.describe_volumes(VolumeIds = volumeIds)
                })

        return dbInstances
                

