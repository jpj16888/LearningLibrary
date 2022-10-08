## centos7中安装Zabbix 5.0

参考地址：https://www.zabbix.com/documentation/5.0/zh/manual/installation/getting_zabbix



#### **1.关闭防火墙及关闭SELinux**

```
关闭防火墙
systemctl stop firewalld&&systemctl disable firewalld
关闭SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
重启
reboot
```

#### **2、替换阿里云Zabbix源**

**shell脚本zabbix_aliyun.sh**

```
vim zabbix_aliyun.sh 
```

**复制下面脚本**

```
#!/bin/bash
 
echo -e "请给出要安装的zabbix版本号，建议使用5.x的版本  \033[31musage：./zabbix_aliyun.sh 4.0|4.4|4.5|5.0|6.0 \033[0m"
echo "例如要安装5.0版本，在命令行写上 ./zabbix_aliyun.sh 5.0"
if [ -z $1 ];then
    exit
fi
VERSION=$1
if [ -f /etc/yum.repos.d/zabbix.repo ];then
    rm -rf /etc/repos.d/zabbix.repo
fi
rpm -qa | grep zabbix-release && rpm -e zabbix-release
rpm -Uvh https://mirrors.aliyun.com/zabbix/zabbix/$VERSION/rhel/7/x86_64/zabbix-release-$VERSION-1.el7.noarch.rpm
sed -i "s@zabbix/.*/rhel@zabbix/$VERSION/rhel@g" /etc/yum.repos.d/zabbix.repo
sed -i 's@repo.zabbix.com@mirrors.aliyun.com/zabbix@g' /etc/yum.repos.d/zabbix.repo
[ $? -eq 0 ] && echo "阿里云的zabbix源替换成功" || exit 1
yum clean all
yum makecache fast
```

**然后执行命令：**

```
bash zabbix_aliyun.sh 5.0    #5.0是要安装的版本
```

#### 安装相应的工具包

由于[zabbix](https://so.csdn.net/so/search?q=zabbix&spm=1001.2101.3001.7020)提供集中的web监控管理界面，因此服务在web界面的呈现需要LAMP架构支持。[安装httpd](https://blog.csdn.net/zhengzaifeidelushang/article/details/106583986) php

```
yum install -y httpd  php php-mysql php-gd libjpeg* php-ldap php-odbc php-pear php-xml php-xmlrpc php-mhash
```

#### 安装Zabbix5.0仓库

```
rpm -ivh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
```

#### **安装Zabbix server and agent**

```
yum install zabbix-server-mysql zabbix-agent2  centos-release-scl -y
```



**启用zabbix-deprecated repository**

```
vim /etc/yum.repos.d/zabbix.repo
```

<img src="C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220331200430227.png" alt="image-20220331200430227" style="zoom:90%;" />

**安装zabbix前端**

```
yum install -y zabbix-web-mysql-scl zabbix-apache-conf-scl
```

#### 安装mysql数据库

**安装数据库**

```
yum -y install mariadb-server mariadb
```

**启动mariadb**

```
systemctl start mariadb&&systemctl enable mariadb
```

对数据库进行安全初始化：一路选择y：

```
 mysql_secure_installation
```



**设置mysql密码**

```
mysqladmin -u root password "123456"    #设置mysql密码为123456
```

**创建初始数据库**

```
mysql -uroot -p                                                 #输入密码123456
create database zabbix character set utf8 collate utf8_bin;
create user zabbix@localhost identified by '123456'; 
grant all privileges on `zabbix`.* to 'zabbix'@'localhost' identified by '123456'; 
update user set authentication_string=password(123456) where user="root";
update user set authentication_string=password(123456) where user="zabbix";
flush privileges;
#密码是password,导入Zabbix数据库结构和数据输入这个密码

use mysql
update user set host='%'  where user ='root' and host ='localhost';

flush privileges;
grant all privileges on `zabbix`.* to 'zabbix'@'%' identified by '123456'; 

flush privileges;

quit;                                                           #退出
```

**为Zabbix服务器配置数据库**

```
vim /etc/zabbix/zabbix_server.conf
修改如下内容：
DBPassword=123456    #密码是 Zabbix 账户的密码 这里是 123456
```

**导入初始架构和数据**

在Zabbix服务器主机上，导入初始架构和数据。系统将提示您输入新创建的密码。

```
解压并修改sql:
gunzip /usr/share/doc/zabbix-server-mysql*/create.sql.gz 
vim /usr/share/doc/zabbix-server-mysql*/create.sql
#在第一行加上
USE zabbix；
#然后重新导入库即可
cat /usr/share/doc/zabbix-server-mysql*/create.sql | mysql -uzabbix -h 192.168.6.150 -p123456 zabbix

```

#### **为Zabbix前端配置PHP**

编辑文件/etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf，取消注释并为您设置正确的时区。

```
vim /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
修改如下内容：
php_value[date.timezone] = Asia/Shanghai
```

#### **启动Zabbix服务**

```
systemctl restart zabbix-server zabbix-agent2 httpd rh-php72-php-fpm&&systemctl enable zabbix-server zabbix-agent2 httpd rh-php72-php-fpm
```

#### **配置Zabbix Web前端**

**浏览器输入** ： http://ip/zabbix,Zabbix      如：http://192.168.6.66/zabbix/setup.php





<img src="C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220331205952507.png" alt="image-20220331205952507" style="zoom:67%;" />



<img src="C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220331210149805.png" alt="image-20220331210149805" style="zoom: 67%;" />

<img src="C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220331210801147.png" alt="image-20220331210801147" style="zoom:80%;" />





##### 处理图形乱码问题

```
#上传字体文件到下列文件，把之前的字体替换
mv graphfont.ttf  /usr/share/zabbix/assets/fonts/graphfont.ttf 
```

#### 客户端安装

```
#下载安装：
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all
yum -y install zabbix-agent2
#修改zabbix-agent配置文件

vim /etc/zabbix/zabbix_agent2.conf

PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Include=/etc/zabbix/zabbix_agentd.d/*.conf
#修改这3个配置
Server=192.168.6.150              #zabbix server服务器IP
ServerActive=192.168.6.150        #  server服务器IP:10051  #主动连接zbbix-server，主要用于自动注册时使用
Hostname=jumpserver            #该名称为在服务端添加主机时的名字，需要注意

#启动zabbix-agent 服务及配置zabbix-agent开机启动
systemctl start zabbix-agent2.service && systemctl enable zabbix-agent2.service



# 客户机测试
yum install zabbix-get -y
zabbix_get -s 192.168.6.150 -p 10050 -k "system.cpu.load[all,avg1]"

# 服务器端测试
yum install zabbix-get -y
zabbix_get -s 192.168.6.150 -p 10050 -k "system.cpu.load[all,avg1]"
```



#### 安装图形工具包grafan

##### 1.处理一些常见报错

```
处理 wget 下载报错 ---颁发的证书已经过期
yum -y install ca-certificates
处理/var/run/yum.pid 已被锁定，PID 为 11776 的另一个程序正在运行
rm -f /var/run/yum.pid
```

##### 2.下载安装grafan

```
wget https://mirrors.tuna.tsinghua.edu.cn/grafana/yum/rpm/grafana-7.2.0-1.x86_64.rpm
yum localinstall -y grafana-7.2.0-1.x86_64.rpm
systemctl start grafana-server.service&&systemctl enable grafana-server.service 
```

##### 3.登录grafan

```
http://192.168.6.150:3000/login
默认账号都是 admin
```



####  grafana-zabbix

1.安装zabbix插件

```
插件查找
grafana-cli  plugins  list-remote |grep zabbix
id: alexanderzobnin-zabbix-app version: 4.2.5
安装下载：
grafana-cli  plugins  install alexanderzobnin-zabbix-app
下载后包的默认地址：
/var/lib/grafana/plugins/
重启grafana 服务
systemctl restart grafana-server.service 
```

在zabbix中新创建一个用户zabbix

 

2.新建一个zabbix数据源

URL =http://192.168.6.150/zabbix/api_jsonrpc.php



```
vim /etc/grafana/grafana.ini
修改如下内容
allow_loading_unsigned_plugins =alexanderzobnin-zabbix-datasource
systemctl restart grafana-server.service 
```

3.导入dashboard模板

