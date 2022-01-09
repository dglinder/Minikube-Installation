#!/usr/bin/env bash
set -u
set -e

# Do everything in the users $HOME directory
cd ~

echo "# Setup your CentOS machine"
echo "## Disable SELinux:"
sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "## Disable Swap:"
sudo swapoff -a

echo "## Adjust firewall settings:"
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload

echo "# Fixing iptables for minikube:"
echo "/proc/sys/net/bridge/bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/75-minikube-fix.conf
sudo sysctl -p

echo "## Install Docker:"

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io

sudo systemctl start docker

sudo systemctl enable docker

echo "## Add user account to docker group:"
sudo usermod --append -G docker ${USER}
GroupOK=0
for G in $(id --name --groups) ; do
  if [[ "${G}" == "docker" ]] ; then
    GroupOK=1
  fi
done

if [[ ${GroupOK} -ne 1 ]] ; then
  echo "Missing the 'docker' group for ${USER}."
  echo "Please logout and login again, then restart the script."
  exit 1
fi

#echo "## Oracle Virtual Box Installation:"
#
#wget https://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo -P /etc/yum.repos.d/
#
#rpm --import https://www.virtualbox.org/download/oracle_vbox.asc
#
#yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#
#yum update
#
#yum install -y binutils kernel-devel kernel-headers libgomp make patch gcc glibc-headers glibc-devel dkms
#
#yum install -y VirtualBox-6.1

echo "## Kubectl Installation:"
K8SRelease="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
curl -LO https://storage.googleapis.com/kubernetes-release/release/${K8SRelease}/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

echo "Installed kubectl version:"
set +e ; kubectl version --short ; set -e

echo "### Conntrack Installation:"
sudo yum install -y conntrack

echo "### Minikube Installation:"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "Installed Minikube version:"
minikube version
  
sudo /usr/local/bin/minikube start --driver=none

