#!/usr/bin/env bash

#Bash script to install ansible control box on minimal debian

# write std out to to log file 
exec > >(tee /root/ansible-setup.log)
# write std err to the same log file
exec 2>&1

echo "Installing sudo:"
apt-get -y install sudo
echo "Installing Python 2.x:"
apt-get -y install python
apt-get -y install python-dev
apt-get -y install python-pip
echo "Installing Python modules needed by ansible:"
pip install paramiko PyYAML Jinja2 httplib2
echo "Installing ansible:"
pip install ansible
echo "Installing Git"
apt-get -y install git
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
#extension needs be .facts to be treated as facts file by ansible
metadata_sym_link=$ansible_local_facts_dir/umd.facts
if [ -f $metadata_sym_link ]; then
    echo "Found user metadata facts file in ${ansible_local_facts_dir}. Will use it"
else
    if ! ln -s $user_metadata_file $metadata_sym_link; then
	echo "unable to create sym link $metadata_sym_link to $user_metadata_file"
	exit 1
    fi
fi

ansible_setup_repo_dir=/root/ansible-setup
if [ -d $ansible_setup_repo_dir ]; then
    echo "Updating existing repo $ansible_setup_repo_dir"
    cd $ansible_setup_repo_dir
    git pull; 
    cd ~
else
    echo "Clonning setup repository from github to $ansible_setup_repo_dir"
    github clone https://github.com/hubward/ansible-setup.git $ansible_setup_repo_dir
    cd ~
fi

setup_ssh_playbook=$ansible_setup_repo_dir/setup-ssh.yml
echo "Invoking ansible playbook: $setup_ssh_playbook" 
ansible-playbook $setup_ssh_playbook -i "localhost," -c local
