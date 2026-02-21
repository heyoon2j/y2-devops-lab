#!/bin/bash
set -e

echo "Stopping SNMP service..."
if systemctl list-units --type=service | grep -q "snmpd.service"; then
    sudo systemctl stop snmpd
    echo "SNMP service stopped."
else
    echo "SNMP service is not running or not installed."
fi
