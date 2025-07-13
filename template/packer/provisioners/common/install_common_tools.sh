#!/bin/bash
echo "[*] Installing common tools"
sudo apt update -y || sudo yum update -y
sudo apt install -y curl unzip || sudo yum install -y curl unzip
