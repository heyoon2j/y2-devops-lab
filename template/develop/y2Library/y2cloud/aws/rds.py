from .awsService import AwsService
import boto3

class Rds(AwsService):
    
    def __init__(self) -> None:
        super().__init__("rds")


    def describeDbInstances(self, **options):
        dbInstances = list()

        response = self._client.describe_db_instances()
        dbInstances = response["DBInstances"]

        while "Marker" in response:
            response = self._client.describe_db_instances(Marker=response["Marker"])
            dbInstances.extend(response["DBInstances"])

        ##################################################
        # Customizing

        dbInstanceList = list()

        for dbInstance in dbInstances:
            """
            dBInstanceIdentifier = dbInstances['DBInstanceIdentifier']

            engine = dbInstances['Engine']
            engine = dbInstances['EngineVersion'] 

            dbInstanceClass = dbInstances['DBInstanceClass']
            # vCpu / memory

            availabilityZone = dbInstance['AvailabilityZone']
   

            # RDS 인경우
            storageType = dbInstance['StorageType']
            allowcatedStorge = dbInstance['AllocatedStorage']
            maxAllocatedStorage = ['MaxAllocatedStorage']

            multiAz = dbInstance['MultiAZ']: True|False,


            # Aurora 인 경우
            dbClusterIdentifier = dbInstance['DBClusterIdentifier']


            # 
            readReplicaDbInstance = dbInstance['ReadReplicaSourceDBInstanceIdentifier']
            readReplicaDbCluster = dbInstance['ReadReplicaSourceDBClusterIdentifier']


            iops = dbInstance['Iops']
            storageThrougput = dbInstance['StorageThroughput']


            # Orcle 'ReplicaMode': 'open-read-only'|'mounted',
            """

            dbInstanceList.append({
                "dbInstanceId" : dbInstance['DBInstanceIdentifier'],
                "engine" : dbInstance['Engine'],
                "engineVersion" : dbInstance['EngineVersion'],
                "dbInstanceClass" : dbInstance['DBInstanceClass'],
                
                # "vCpu" : 
                # "memory" : 

                "az" : dbInstance['AvailabilityZone'],

                # Aurora 인 경우
                "dbClusterId" : dbInstance['DBClusterIdentifier'] if 'DBClusterIdentifier' in dbInstance else None,

                # RDS 인경우
                "storageType" : dbInstance['StorageType'] if 'StorageType' in dbInstance else None,


                "storageSize" : None if 'DBClusterIdentifier' in dbInstance else dbInstance['AllocatedStorage'],
                ##maxAllocatedStorage = ['MaxAllocatedStorage']

                "multiAz" : dbInstance['MultiAZ'] # True|False,

                # ETC
                # "readReplicaDbInstanceId" : dbInstance['ReadReplicaSourceDBInstanceIdentifier'],
                # "readReplicaDbClusterId" : dbInstance['ReadReplicaSourceDBClusterIdentifier'],
                # "iops" : dbInstance['Iops'],
                # "storageThrougput" : dbInstance['StorageThroughput']
            })

        return dbInstanceList
                

