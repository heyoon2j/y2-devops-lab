#!/bin/bash

##################################   check list   ##############################################
userSvcName="amazon-ssm-agent.service"
userSearch="Active"

isExist=`systemctl status ${userSvcName} 2> /dev/null | grep "${userSearch}"`

if [ "${isExist}" == "" ];then
  echo "false"
else
  echo "true"
fi



##################################   check status   ##############################################
status=$(systemctl show amazon-ssm-agent.service --no-page)
#active_state=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)
active_state=$(echo "${status}" | grep 'ActiveState=' | awk -F= '{ print $2 }')
if [ "${active_state}" == "active" ]
then
  echo "active"
elif [ "${active_state}" == "activating" ]
then
  echo "active"
else
  echo "inactive"
fi