## **1.ens33网卡设置**

```
[root@centos7 network-scripts]# cat ifcfg-ens33
HWADDR=00:50:56:3F:11:15 #网卡MAC
TYPE=Ethernet #网卡类型:以太网
PROXY_METHOD=none #代理方式:关闭状态
BROWSER_ONLY=no #只是浏览器
BOOTPROTO=dhcp #  网络参数设置：静态IP：STATIC或、动态IP：DCHP、NONE：不指定
DEFROUTE=yes #设置为默认路由
IPV4_FAILURE_FATAL=no #是否开启IPV4致命错误检测
IPV6INIT=yes #IPV6是否自动初始化
IPV6_AUTOCONF=yes #IPV6是否自动配置
IPV6_DEFROUTE=yes  #IPV6是否可以为默认路由
IPV6_FAILURE_FATAL=no #是不开启IPV6致命错误检测
IPV6_ADDR_GEN_MODE=stable-privacy IPV6 #地址生成模型
NAME=ens33 #网卡物理设备名称
DEVICE=ens33 #网卡设备名称
USERCTL=no #yes：非root用户可以控制设备，no：非root用户不允许控制设备
UUID=fe10e832-ba9c-3b18-8a86-eb6fdd5e780d
ONBOOT=yes #yes：设备在boot时被激活，no：设备在boot时不被激活
MASTER=bond0
SLAVE=yes
BONDING_MASTER=yes

```



## **2.ens37网卡设置**

```
[root@centos7 network-scripts]# cat ifcfg-ens37
HWADDR=00:50:56:28:A2:75
TYPE=Ethernet #网卡类型:以太网
PROXY_METHOD=none #代理方式:关闭状态
BROWSER_ONLY=no #只是浏览器
BOOTPROTO=dhcp #  网络参数设置：静态IP：STATIC或、动态IP：DCHP、NONE：不指定
DEFROUTE=yes #设置为默认路由
IPV4_FAILURE_FATAL=no #是否开启IPV4致命错误检测
IPV6INIT=yes #IPV6是否自动初始化
IPV6_AUTOCONF=yes #IPV6是否自动配置
IPV6_DEFROUTE=yes  #IPV6是否可以为默认路由
IPV6_FAILURE_FATAL=no #是不开启IPV6致命错误检测
IPV6_ADDR_GEN_MODE=stable-privacy IPV6 #地址生成模型
NAME=ens37 #网卡物理设备名称
DEVICE=ens37 #网卡设备名称
UUID=49ecbce1-16ed-40ec-878b-b97f6ade6744
USERCTL=no #yes：非root用户可以控制设备，no：非root用户不允许控制设备
ONBOOT=yes #yes：设备在boot时被激活，no：设备在boot时不被激活
MASTER=bond0
SLAVE=yes
BONDING_MASTER=yes

```

## 3.ifcfg-bond0 网卡设置

```
[root@centos7 network-scripts]# cat ifcfg-bond0 
DEVICE=bond0
TYPE=Bond
BOOTPROTO=static  #  网络参数设置：静态IP：STATIC或、动态IP：DCHP、NONE：不指定
IPADDR=192.168.6.66
netmask=255.255.255.0
GATEWAY=192.168.6.2
DNS1=192.168.6.2
ONBOOT=yes #yes：设备在boot时被激活，no：设备在boot时不被激活
BONDING_OPTS="miimon=10   mode=6 " 
ZONE=public
USERCTL=no  #yes：非root用户可以控制设备，no：非root用户不允许控制设备
NM_CONTROLLED=no
BONDING_MASTER=yes

```

**centos7默认没有加bonding内核模板**

#### 加载内核模板

**modprobe --first-time bonding**

#### **查看是否加载成功**     

 **lsmod | grep bonding 或者 modinfo bonding**

#### **重启网络服务**

**service network restart**

#### 需要禁用NetworkManager

**systemctl stop NetworkManager.service**

**systemctl disable NetworkManager.service**

#### 关闭防火墙

**systemctl stop firewalld.service  #关闭防火墙**

**systemctl disable firewalld.service   #关闭开机启动防火墙**

#### 查看bond0网卡状态

**cat /proc/net/bonding/bond0** 

#### 删除网卡相关配置缓存

**cp /etc/udev/rules.d/70-persistent-ipoib.rules  /etc/udev/rules.d/70-persistent-ipoib.rules_bak**

**rm -rf /etc/udev/rules.d/70-persistent-ipoib.rules** 

#### 重启服务器

**reboot**



