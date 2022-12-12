#!/bin/bash
useradd -G wheel sysadmin -m -u 520

echo "sysadmin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-cloud-init-users

# change ssh default port

sudo sed -i 's/\#Port 22/Port 40022/g' /etc/ssh/sshd_config
sudo semanage port -a -t ssh_port_t -p tcp 40022

# change password authentication yes
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# change cloud init passwd auth true
sudo sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/' /etc/cloud/cloud.cfg

service sshd restart > /dev/null 2>&1;

# sysadmin set password

echo 'sysadmin:koreanre12!' | chpasswd
rm /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

userdel ec2-user -r