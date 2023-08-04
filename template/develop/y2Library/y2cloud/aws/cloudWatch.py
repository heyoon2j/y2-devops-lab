from .awsService import AwsService
import boto3

class CloudWatch(AwsService):
    
    def __init__(self) -> None:
        super().__init__("cloudwatch")


    def get_metric_statistics_daily(self, options):

        response = self._client.get_metric_statistics(
            Namespace=options["Namespace"],
            MetricName=options["MetricName"],
            Dimensions=options["Dimensions"],
            StartTime=options["StartTime"],
            EndTime=options["EndTime"],
            Period=options["Period"],
            Statistics=options["Statistics"],
        )

        if len(response['Datapoints']) == 0:
            return [0, 0, 0]

        minValue = response['Datapoints'][0]['Maximum']
        maxValue = response['Datapoints'][0]['Maximum']
        avgValue = response['Datapoints'][0]['Average']

        """
        for datapoint in response['Datapoints']:
            avgValue = datapoint['Average']

            if datapoint['Maximum'] > maxValue:
                maxValue = datapoint['Maximum']

            if minValue > datapoint['Minimum']:
                minValue = datapoint['Minimum']
        
        avgValue /= len(response['Datapoints'])
        """

        if options["MetricName"] == 'FreeableMemory':
            avgValue = avgValue/1024/1024/1024
            minValue = minValue/1024/1024/1024
            maxValue = maxValue/1024/1024/1024


        return [round(avgValue, 2), round(maxValue, 2), round(minValue, 2)]

