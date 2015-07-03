#!/usr/bin/env bash

#Bash script to install ansible control box on minimal debian

# write std out to to log file 
exec > >(tee /home/$USER/vm-post-install-script.log)
# write std err to the same log file
exec 2>&1

echo "Installing sudo:"
apt-get -y install sudo
echo "Installing socat:"
apt-get -y install socat
echo "Installing curl: "
apt-get -y install curl
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
user_metadata_file=$user_metadata_dir/openstack/latest/user_data
if  [ ! -f $user_metdata_file ]; then
    echo "$user_metadata_file not found." 
    exit 1;
fi

ansible_user_management_repo_dir=/home/$USER/ansible-user-management
if [ -d $ansible_user_management_repo_dir ]; then
    echo "Updating existing repo $ansible_user_management_repo_dir"
    cd $ansible_user_management_repo_dir
    git pull; 
    cd ~
else
    echo "Clonning setup repository from github to $ansible_user_management_repo_dir"
    git clone https://github.com/hubward/ansible-setup-playbooks.git $ansible_user_management_repo_dir
    cd ~
fi

setup_ssh_playbook=$ansible_user_management_repo_dir/setup_users.yml
echo "Invoking ansible playbook: $setup_ssh_playbook" 
ansible-playbook $setup_ssh_playbook -i "localhost," -c local -e "@$user_metadata_file"
rm -r $ansible_user_management_repo_dir
