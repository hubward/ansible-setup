#!/usr/bin/env bash

#Bash script to install ansible control box on minimal debian

# write std out to to log file 
exec > >(tee /root/ansible-setup.log)
# write std err to the same log file
exec 2>&1

echo "Installing sudo:"
apt-get install sudo
echo "Creating operators group 'ops'"
groupadd ops
if grep -q "%ops" /etc/sudoers; then
    echo "Group ops already found in /etc/sudoers. No changes will be applied to /etc/sudoers"
else
    echo "Allowed sudo for group ops members without password"
    echo "Allow members of group ops to sudo all commands without password" >> /etc/sudoers
    echo "%ops ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

echo "Installing Python 2.x:"
apt-get install pip-python
apt-get install python-dev
echo "Installing Python modules needed by ansible:"
pip install paramiko PyYAML Jinja2 httplib2
echo "Installing ansible:"
pip install ansible
echo "Configuring ansible to use SoftLayer inventory:"
ansible_version=$(ansible --version | grep -o -P "[0-9].[0-9].[0-9]$" >&1)
wget -O /etc/ansible/hosts https://rawgit.com/ansible/ansible/release${ansible_version}/plugins/inventory/softlayer.py
chgrp ops /etc/ansible/hosts
chmod g+x /etc/ansible/hosts
echo "Installing Git"
apt-get install git
echo "Mounting user metadata:"
user_metadata_dir="/mnt/user-metadata"
if ! mountpoint -q $user_metadata_dir; then
    mkdir -p $user_metadata_dir
    if mount /dev/xvdh1 $user_metadata_dir; then
	echo "Mounted${user_metadata_dir}"
    else
	exit 1;
    fi
else
    echo "${user_metadata_dir} already maunted"
fi

if ! [[ -f "${user_metadata_dir}/meata.js" ]]; then
    echo "No meata.js file found in {$user_metadata_dir}"
    exit 1;
fi
echo "test1"
wget -q https://rawgit.com/hubward/ansible-setup/master/setup-ssh.py -O /root/setup-ssh.py
chmod u+x /root/setup-ssh.py
/root/setup-ssh.py
