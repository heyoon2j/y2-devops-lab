from .awsService import AwsService
import boto3

class Ec2(AwsService):
    
    def __init__(self) -> None:
        super().__init__("ec2")


    def describe_volumes(self, **options):
        response = self._client.describe_volumes(VolumeIds=options["VolumeIds"])

        # Customizing
        volume = 0
        for v in response["Volumes"]:
            volume += v["Size"]         

        return volume


    def describe_instance_types(self, **options):
        instanceTypeDict : dict = {}
        instanceTypes : list = []

        response = self._client.describe_instance_types()
        instanceTypes = response["InstanceTypes"]

        while "NextToken" in response:
            response = self._client.describe_instance_types(NextToken=response["NextToken"])
            instanceTypes.extend(response["InstanceTypes"])


        # Customizing
        for it in instanceTypes:
            instanceTypeDict[it["InstanceType"]] = {"vCpu": it["VCpuInfo"]["DefaultVCpus"], "mem": int(it["MemoryInfo"]["SizeInMiB"]/1024)}
        
        return instanceTypeDict
        


    def describe_instances(self, **options):
        instances = list()
        reservations = list()

        response = self._client.describe_instances()
        reservations = response["Reservations"]

        while "NextToken" in response:
            response = self._client.describe_instances(NextToken=response["NextToken"])
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

                instances.append({
                    "instanceId" : instance["InstanceId"],
                    "hostName" : hostName,
                    "ipAddress" :instance["PrivateIpAddress"],
                    "account" : reservation["OwnerId"],
                    "instanceType" : instance["InstanceType"],           
                    "vCpu" : instanceTypeDict[instance["InstanceType"]]["vCpu"],
                    "memory" : instanceTypeDict[instance["InstanceType"]]["mem"],
                    "volume" : self.describe_volumes(VolumeIds = volumeIds)
                })

        return instances
