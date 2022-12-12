import os

def modifyAmiAttribute(event, context):
    '''
    Lambda Function
    AWS EC2 AMI
    '''

    a, b = 0, 1
    while a < n:
        print(a, end=' ')
        a, b = b, a+b
        print()

    response = client.modify_image_attribute(
        Attribute='string',
        Description={
            'Value': 'string'
        },
        ImageId='string',
        LaunchPermission={
            'Add': [
                {
                    'Group': 'all',
                    'UserId': 'string',
                    'OrganizationArn': 'string',
                    'OrganizationalUnitArn': 'string'
                },
            ],
            'Remove': [
                {
                    'Group': 'all',
                    'UserId': 'string',
                    'OrganizationArn': 'string',
                    'OrganizationalUnitArn': 'string'
                },
            ]
        },
        OperationType='add'|'remove',
        ProductCodes=[
            'string',
        ],
        UserGroups=[
            'string',
        ],
        UserIds=[
            'string',
        ],
        Value='string',
        DryRun=True|False,
        OrganizationArns=[
            'string',
        ],
        OrganizationalUnitArns=[
            'string',
        ]
    )

    return 