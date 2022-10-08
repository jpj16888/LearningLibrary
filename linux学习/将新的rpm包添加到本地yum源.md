### 将新的rpm包添加到本地yum源

#### 0、开始

首先推荐两个很不错的现在rpm的地址

https://pkgs.org/

http://rpm.pbone.net/

在安装zabbix的时候，光盘中并没有php-bcmath-5.4.16-42.el7.x86_64.rpm和php-mbstring-5.4.16-42.el7.x86_64.rpm两个包。

所以需要将两个包在网上下载到本地后，然后进行本地yum源的更新。

现在以php-bcmath和php-mbstring为例进行描述，如何将新的rpm包添加到本地yum源。

#### 1、下载rpm包

```shell
wget ftp://mirror.switch.ch/pool/4/mirror/scientificlinux/7.1/x86_64/updates/security/php-bcmath-5.4.16-42.el7.x86_64.rpm

wget ftp://mirror.switch.ch/pool/4/mirror/scientificlinux/7.1/x86_64/updates/security/php-mbstring-5.4.16-42.el7.x86_64.rpm
```

但是一定要注意安装包的版本，一定要和本地源中的其他软件版本一致，否则会提示依赖错误。

 

#### 2、将光盘中的Packages文件夹，复制到本地目录

挂载：mount /dev/cdrom /mnt

mkdir /usr/local/yum

复制：cp -r /mnt/Packages /usr/local/yum

在将新下载的包复制到/usr/local/yum/Packages中

3、创建本地yum仓库
yum clean all

createrepo /usr/local/yum

yum文件夹下会产生repodata的文件夹

#### 4、本地yum源文件配置

https://blog.csdn.net/nowzhangjunzhe/article/details/81195443

依据此文章中的配置文件，进行配置，将路径更改为正确的路径即可

baseurl=file:///usr/local/yum

#### 5、最后进行包的安装

yum install php-bcmath

yum install php-mbstring


