import AwsService
import boto3

class Ec2(AwsService):
    
    def __init__(self, credentials) -> None:
        self.name = "ec2"
        self.__credentials = credentials
        self.__client = credentials.client('ec2')

    @property
    def credentials(self):
        return self.__credentials

    @credentials.setter
    def credentials(self, credentials):
        self.__credentials = credentials
        

    def describe_volumes(self, **options):
        response = self.__client.describe_volumes(VolumeIds=options["VolumeIds"])

        # Customizing
        volume = 0
        for v in response["Volumes"]:
            volume += v["Size"]         

        return volume



    def describe_instance_types(self, **options):
        instanceTypeDict : dict = {}
        instanceTypes : list = []
        response = None
        
        while True:
            if len(instanceTypeDict) > 0:
                response = self.__client.describe_instance_types(NextToken=response["NextToken"])
            else:
                response = self.__client.describe_instance_types()
            instanceTypes.extend(response["InstanceTypes"])

            if "NextToken" not in response:
                break

        # Customizing
        for it in instanceTypes:
            instanceTypeDict[it["InstanceType"]] = {"vCpu": it["VCpuInfo"]["DefaultVCpus"], "mem": int(it["MemoryInfo"]["SizeInMiB"]/1024)}
        
        return instanceTypeDict
        


    def describe_instances(self, **options):
        reservations = list()
        instances = list()

        response = None
        while True:
            if len(reservations) > 0:
                response = self.__client.describe_instances(NextToken=response["NextToken"])
            else:
                response = self.__client.describe_instances() 
            reservations.extend(response["Reservations"])

            if  "NextToken" not in response: break


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

                instances.append({
                    "instanceId" : instance["InstanceId"],
                    "hostName" : hostName,
                    "ipAddress" :instance["PrivateIpAddress"],
                    "account" : reservation["OwnerId"],
                    "instanceType" : instance["InstanceType"],           
                    "vCpu" : instanceTypeDict[instance["InstanceType"]]["vCpu"],
                    "memory" : instanceTypeDict[instance["InstanceType"]]["mem"],
                    "volume" : self.describe_volumes({"VolumeIds" : volumeIds})
                })

        return instances
