#!/usr/bin/python
from datetime import datetime
from datetime import timedelta
import sys
from optparse import OptionParser
from pytz import timezone
import boto3

### Arguments
parser = OptionParser()
parser.add_option("-i", "--instance-id", dest="instance_id", help="DBInstanceIdentifier")
parser.add_option("-a", "--access-key", dest="access_key", help="AWS Access Key")
parser.add_option("-k", "--secret-key", dest="secret_key", help="AWS Secret Access Key")
parser.add_option("-m", "--metric", dest="metric", help="RDS cloudwatch metric")
parser.add_option("-r", "--region", dest="region", help="RDS region")

(options, args) = parser.parse_args()

if (options.instance_id == None):
    parser.error("-i DBInstanceIdentifier is required")
#if (options.access_key == None):
#    parser.error("-a AWS Access Key is required")
#if (options.secret_key == None):
#    parser.error("-k AWS Secret Key is required")
if (options.metric == None):
    parser.error("-m RDS cloudwatch metric is required")
###

### Real code
metrics = {"CPUUtilization":{"type":"float", "value":None},
    "ReadLatency":{"type":"float", "value":None},
    "DatabaseConnections":{"type":"int", "value":None},
    "FreeableMemory":{"type":"float", "value":None},
    "ReadIOPS":{"type":"int", "value":None},
    "WriteLatency":{"type":"float", "value":None},
    "WriteThroughput":{"type":"float", "value":None},
    "WriteIOPS":{"type":"int", "value":None},
    "SwapUsage":{"type":"float", "value":None},
    "ReadThroughput":{"type":"float", "value":None},
    "DiskQueueDepth":{"type":"float", "value":None},
    "ReplicaLag":{"type":"int", "value":None},
    "DiskQueueDepth":{"type":"float", "value":None},
    "ReplicaLag":{"type":"int", "value":None},
    "NetworkReceiveThroughput":{"type":"float", "value":None},
    "NetworkTransmitThroughput":{"type":"float", "value":None},
    "FreeStorageSpace":{"type":"float", "value":None}}
#end = datetime.datetime.utcnow()
end = datetime.now(timezone('UTC'))
start = end - timedelta(minutes=5)


### Zabbix hack for supporting FQDN addresses
### This is useful if you have instances with the same nam but in diffrent AWS locations (i.e. db1 in eu-central-1 and db1 in us-east-1)
if "." in options.instance_id:
    options.instance_id = options.instance_id.split(".")[0]

### Get the region
if (options.region == None):
    options.region = 'ap-northeast-2'

conn = boto3.client('cloudwatch', region_name=options.region) #aws_access_key_id=options.access_key, aws_secret_access_key=options.secret_key, region_name=options.region)

for k,vh in metrics.items():

    if (k == options.metric):

        try:
                res = conn.get_metric_statistics(Namespace="AWS/RDS", MetricName=k, Dimensions=[{'Name': "DBInstanceIdentifier", 'Value': options.instance_id}], StartTime=start, EndTime=end, Period=60, Statistics=["Average"])
        except Exception as e:
                print("status err Error running rds_stats: %s" % e.error_message)
                sys.exit(1)
        average = res.get('Datapoints')[-1].get('Average') # last item in result set
        if (k == "FreeStorageSpace" or k == "FreeableMemory"):
                average = average / 1024.0**3.0
        if vh["type"] == "float":
                metrics[k]["value"] = "%.4f" % average
        if vh["type"] == "int":
                metrics[k]["value"] = "%i" % average

        #print "metric %s %s %s" % (k, vh["type"], vh["value"])
        print("%s" % (vh["value"]))
        break