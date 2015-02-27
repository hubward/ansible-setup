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
echo "Configuring ansible to use user metadata as facts:"
user_metadata_dir="/mnt/user-metadata"
#mount /dev/xvdh1. This special device is used by softlayer to bring
#user provided metadata upon virtual service creation. Metadata is
#written inside a file meta.js
if ! mountpoint -q $user_metadata_dir; then
    mkdir -p $user_metadata_dir
    if mount /dev/xvdh1 $user_metadata_dir; then
	echo "Mounted ${user_metadata_dir}"
    else
	echo "pass"
#	exit 1;
    fi
else
    echo "${user_metadata_dir} already maunted"
fi
user_metadata_file=$user_metadata_dir/meta.js
if  [ ! -f $user_metdata_file ]; then
    echo "$user_metadata_file not found." 
    exit 1;
fi
#create a link inside the /etc/ansible/facts.do to the meta.js.
#Ansible treats all files in this directory as custom facts files
ansible_local_facts_dir="/etc/ansible/facts.d"
mkdir -p $ansible_local_facts_dir
metadata_sym_link=$ansible_local_facts_dir/user_meta_data.js
if [ -f $metadata_sym_link ]; then
    echo "Found user metadata facts file in ${ansible_local_facts_dir}. Will use it"
else
    if ! ln -s $user_metadata_file $metadata_sym_link; then
	echo "unable to create sym link $metadata_sym_link to $user_metadata_file"
	exit 1
    fi
fi
