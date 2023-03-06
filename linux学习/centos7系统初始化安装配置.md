

#### centos7系统初始化安装配置

编写脚本  

```
#!/bin/bash

systemctl stop firewalld&&systemctl disable firewalld		 #关闭防火墙并设置开机时禁用
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config	 #关闭SELinux

#yum 源配置
yum install wget vim -y
#备份
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
#下载新的 CentOS-Base.repo 到 /etc/yum.repos.d/
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#清除原有yum缓存 
yum clean all
#更新缓存 
yum makecache fast

#安装常见依赖包

yum -y install gcc glibc-devel make ncurses-devel openssl-devel xmlto perl wget gtk2-devel binutils-devel gcc-c++ bison-devel  ncurses-devel  bison perl perl-devel   boost boost-devel boost-doc  libaio

#删除现有网卡
rm -rf /etc/sysconfig/network-scripts/ifcfg-ens*
#配置网卡信息
cat >> /etc/sysconfig/network-scripts/ifcfg-ens32 <<EOF
YPE=Ethernet
BOOTPROTO=none     # 等号后面写：dhcp 表示动态获取IP地址，  satic 表示表态IP，none表示不指定，就是静态。
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
NAME=ens32   #网卡名
UUID=50eff37c-72b4-407a-a3ee-9ef8ca746b95
DEVICE=ens32
ONBOOT=yes
NETMASK=255.255.255.0
IPADDR=192.168.6.88
PREFIX=24
GATEWAY=192.168.6.2
DNS1=192.168.6.2
DNS2=8.8.8.8
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_PRIVACY=no
EOF


```

systemctl restart network  #重启网卡服务

reboot #重启



##### 监控工具bottom安装

```
yum install dnf
dnf install 'dnf-command(copr)'
dnf copr enable atim/bottom
#进入页面
btm


```

