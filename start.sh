#!/bin/bash -e
hostnamectl set-hostname k8s-01
echo "127.0.0.1 $(hostname)" >> /etc/hosts
sed -i "s/^SELINUX=.*/SELINUX=disabled/" /etc/selinux/config 
setenforce 0
systemctl stop firewalld
systemctl disable firewalld
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo 
yum clean all
yum makecache 
yum update
yum install ntp -y
ntpdate ntp.aliyun.com
hwclock -w
yum install -y bash-completion
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum update
yum install -y docker-ce-3:19.03.9-3.el7.x86_64 docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://6fnywwd8.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab 
cat <<EOF |sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat << EOF |sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-5.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install -y kernel-lt
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg
