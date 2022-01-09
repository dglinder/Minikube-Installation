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
    -y \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io

sudo systemctl start docker

sudo systemctl enable docker

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
#
echo "## Kubectl Installation:"
K8SRelease="$(https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
curl -LO https://storage.googleapis.com/kubernetes-release/release/${K8SRelease}/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

echo "Installed kubectl version:"
kubectl version --short

echo "### Conntrack Installation:"
yum install -y conntrack -y

echo "### Minikube Installation:"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

echo "Installed Minikube version:"
minikube version
  
minikube start --driver=none

