#!/bin/bash
echo "[GCP] Initializing CSP-level settings..."
OS_FAMILY=$(grep -i '^ID=' /etc/os-release | cut -d'=' -f2)
case "$OS_FAMILY" in
  rocky) echo "Applying GCP Rocky Linux settings";;
  ubuntu) echo "Applying GCP Ubuntu settings";;
  *) echo "Unknown OS: $OS_FAMILY";;
esac
