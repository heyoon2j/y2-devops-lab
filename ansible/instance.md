```
# 수정 O
instanceCount=1
imageId=
instanceType="t3.medium"
subnetId=


# 수정 X
hibernationOptions=false
enableMonitoring=false
shutdownBehavior="stop"
dnsOptions="
{
  "HostnameType": "ip-name"|"resource-name",
  "EnableResourceNameDnsARecord": true|false,
  "EnableResourceNameDnsAAAARecord": true|false
}"
placement="
{
  "AvailabilityZone": "string",
  "Affinity": "string",
  "GroupName": "string",
  "PartitionNumber": integer,
  "HostId": "string",
  "Tenancy": "default"|"dedicated"|"host",
  "SpreadDomain": "string",
  "HostResourceGroupArn": "string"
}"
metadataOptions="
{
  "HttpTokens": "optional"|"required",
  "HttpPutResponseHopLimit": integer,
  "HttpEndpoint": "disabled"|"enabled",
  "HttpProtocolIpv6": "disabled"|"enabled",
  "InstanceMetadataTags": "disabled"|"enabled"
}
"
userData=


aws ec2 run-instances \
    --count $instanceCount
    --image-id $imageId
    --instance-type $instanceType
    --subnet-id $subnetId
    --security-groups []
    [--private-dns-name-options <value>]
    [--associate-public-ip-address | --no-associate-public-ip-address]
    --network-interfaces []
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":20,\"DeleteOnTermination\":false}}]"

[--private-ip-address <value>]
[--secondary-private-ip-addresses <value>]
[--secondary-private-ip-address-count <value>]

    [--disable-api-termination | --enable-api-termination]
    [--disable-api-stop | --no-disable-api-stop]
    [--iam-instance-profile <value>]
    [--placement <value>]
    --instance-initiated-shutdown-behavior $shutdownBehavior
    --monitoring $enableMonitoring
    --hibernation-options $hibernationOptions

    --user-data $userData
    --metadata-options $metadataOptions
    --tag-specifications 'ResourceType=instance,Tags=[{Key=webserver,Value=production}]' 'ResourceType=volume,Tags=[{Key=cost-center,Value=cc123}]'

[--client-token <value>]

[--instance-market-options <value>]
[--elastic-gpu-specification <value>]
[--elastic-inference-accelerators <value>]
[--launch-template <value>]

[--maintenance-options <value>]
[--credit-specification <value>]
[--ebs-optimized | --no-ebs-optimized]
[--ramdisk-id <value>]
[--cpu-options <value>]
[--enclave-options <value>]
[--additional-info <value>]



[--dry-run | --no-dry-run]
[--cli-input-json <value>]
[--generate-cli-skeleton <value>]
[--debug]
[--endpoint-url <value>]
[--no-verify-ssl]
[--no-paginate]
[--output <value>]
[--query <value>]
[--profile <value>]
[--region <value>]
[--version <value>]
[--color <value>]
[--no-sign-request]
[--ca-bundle <value>]
[--cli-read-timeout <value>]
[--cli-connect-timeout <value>]
```