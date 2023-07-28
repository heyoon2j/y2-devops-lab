import boto3
from datetime import datetime


def get_metric_statistics_daily(client, options):

    response = client.get_metric_statistics(
        Namespace=options["Namespace"],
        MetricName=options["MetricName"],
        Dimensions=options["Dimensions"],
        StartTime=options["StartTime"],
        EndTime=options["EndTime"],
        Period=options["Period"],
        Statistics=options["Statistics"],
        Unit=options["Unit"]
    )

    if len(response['Datapoints']) == 0:
        return [0, 0, 0]

    maxValue = 0
    avgValue = 0

    for datapoint in response['Datapoints']:
        avgValue = datapoint['Average']

        if datapoint['Maximum'] > maxValue:
            maxValue = datapoint['Maximum']

        if minValue > datapoint['Minimum']:
            minValue = datapoint['Minimum']


    avgValue /= len(response['Datapoints'])
    print(response)
    print(avgValue, maxValue, minValue)
    #return [avgValue, maxValue, minValue]



def main():
    default_cred = boto3.session.Session(profile_name="default")
    logs = default_cred.client('cloudwatch')

    options = {
        'Namespace': 'AWS/RDS',
        'MetricName' : 'CPUUtilization',
        'Dimensions' : [
            {
                'Name': 'DBInstanceIdentifier',
                'Value': 'database-1-instance-1'
            }
        ],
        'StartTime': datetime(2023, 7, 26),
        'EndTime' : datetime(2023, 7, 27),
        'Period' : 300,
        'Statistics' : [
            'Average','Maximum', 'Minimum'
        ],
        'Unit' : 'Percent'
    }

    get_metric_statistics_daily(client=logs, options=options)



if __name__ == '__main__':
    main()