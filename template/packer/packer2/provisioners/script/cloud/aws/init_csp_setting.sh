#!/bin/bash
echo "[AWS] Initializing CSP-level settings..."
OS_FAMILY=$(grep -i '^ID=' /etc/os-release | cut -d'=' -f2)
case "$OS_FAMILY" in
  rocky) echo "Applying AWS Rocky Linux settings";;
  ubuntu) echo "Applying AWS Ubuntu settings";;
  *) echo "Unknown OS: $OS_FAMILY";;
esac
