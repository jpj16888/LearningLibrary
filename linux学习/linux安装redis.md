# CentOS7 安装 Redis6

[TOC]

参考：https://blog.csdn.net/kuangpengfei/article/details/122897961

## 单机版安装

### 下载redis

```shell
cd /home
yum install -y wget
wget https://download.redis.io/releases/redis-6.0.9.tar.gz
```

### 环境准备

```shell
yum install gcc -y
gcc -v
yum -y install centos-release-scl  # 升级到9.1版本
yum -y install centos-release-scl devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
	
scl enable devtoolset-9 bash
```

错误处理:   

```
另一个应用程序是：PackageKit
 内存： 63 M RSS （479 MB VSZ）
已启动： Sun Jul 31 12:55:36 2022 - 00:06之前

```

```shell
rm -f /var/run/yum.pid
```



### 执行安装

```shell
tar -zxvf redis-6.0.9.tar.gz
cd redis-6.0.9
mkdir -p /opt/soft/redis6
make    #这里如果make出错，可以执行make distclean命令，然后重新 make
make install PREFIX=/opt/soft/redis6  #将redis服务安装到该目录下
```

### 配置环境变量

```shell
echo 'export  REDIS_HOME=/opt/soft/redis6' >> /etc/profile 

echo 'export  PATH=$REDIS_HOME/bin:$PATH' >> /etc/profile

source /etc/profile 
```

### 安装系统服务

这里Redis6版本有一个坑，需要先将install_server.sh文件中的部分内容注释掉，否则会导致无法安装。

```shell
cd utils
vim ./install_server.sh
```

注释掉如下内容

```shell
#bail if this system is managed by systemd
#_pid_1_exe="$(readlink -f /proc/1/exe)"
#if [ "${_pid_1_exe##*/}" = systemd ] 
#then 
#       echo "This systems seems to use systemd."
#       echo "Please take a look at the provided example service unit files in #this directory, and adapt and ins
#tall them. Sorry!"
#exit 1 
#fi
```

### 执行安装

```shell
./install_server.sh
```

**如果要在本机上安装多个redis实例，只需要多次执行该脚本，设置不同的端口号即可**。

安装完成后，在/etc/redis目录下，会有对应端口号的配置文件，比如6379.conf。 后续redis的启动就是依赖该配置文件。

### 安装完成后的一些其他配置

```shell
vim /etc/redis/6379.conf #注意： 这个端口号是在安装的时候所设置的端口号
bind 192.168.6.132(自己机器对应的ip)   #绑定ip地址，使得该redis实例可以与其他实例通信
daemonize yes #后台启动  
protected-mode no #关闭保护模式，开启的话，只有本机才可以访问redis
pidfile /var/run/redis_6379.pid
logfile /var/log/redis_6379.log
dbfilename dump-6379.rdb
dir /var/lib/redis/6379
```

### 启动方式

```shell
service redis_端口号 start
```

这里的端口号就是在执行./install_server.sh时 设置的端口号

```shell
service redis_6379 start    #启动redis_6379服务
service redis_6379 status   #查看状态
service redis_6379 restart  #重启服务
service redis_6379 stop     #停止服务  
```







## redis6集群配置

下载及安装

```
#下载
cd /home
yum install -y wget
wget https://download.redis.io/releases/redis-6.0.9.tar.gz
# 升级到9.1版本
yum install gcc -y 
yum -y install centos-release-scl devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils

scl enable devtoolset-9 bash
#编译安装
tar -zxvf redis-6.0.9.tar.gz
cd /home/redis-6.0.9/
make MALLOC=libc
make PREFIX=/home/redis-6.0.9  install
```



#### 创建相应目录，修改相应配置

```shell
mkdir /home/rediscluster/{7001,7002} -p

mkdir /home/rediscluster/{7001,7002}/{conf,data,log} -p

cp /home/redis-6.0.9/redis.conf  /home/rediscluster/7001/conf/

```

#### 修改配置文件

vim /home/rediscluster/7001/conf/redis.conf

```shell 
bind 192.168.6.132    # (自己机器对应的ip) 绑定ip地址，使得该redis实例可以与其他实例通信

port 7001

daemonize yes #后台启动  

protected-mode no #关闭保护模式，开启的话，只有本机才可以访问redis

pidfile "/home/rediscluster/7001/data/redis_7001.pid"

logfile "i"

dbfilename dump-7001.rdb

dir "/home/rediscluster/7001/data/"

masterauth "1234"   #设置密码，redis启用密码认证一定要requirepass和masterauth同时设置；masterauth作用：主要是针对master对应的slave节点设置的，在slave节点数据同步的时候用到。requirepass作用：对登录权限做限制，redis每个节点的requirepass可以是独立、不同的。requirepass验证客户端，masterauth验证从库。

requirepass "1234"  

cluster-enabled yes

cluster-node-timeout 15000

```

```shell

sed -i 's#bind 127.0.0.1#bind 192.168.6.132#g' /home/rediscluster/7001/conf/redis.conf

sed -i 's#6379#7001#g' /home/rediscluster/7001/conf/redis.conf
 #后台启动  
sed -i 's#daemonize no#daemonize yes#g' /home/rediscluster/7001/conf/redis.conf
 #关闭保护模式，开启的话，只有本机才可以访问redis
sed -i 's#protected-mode yes#protected-mode no#g' /home/rediscluster/7001/conf/redis.conf
# 当Redis以守护进程方式运行时，Redis默认会把pid写入文件，可以通过pidfile指定
sed -i 's#pidfile /var/run/redis_7001.pid#pidfile "/home/rediscluster/7001/data/redis_7001.pid"#g' /home/rediscluster/7001/conf/redis.conf
#配置为日志记
sed -i 's#logfile ""#logfile "/home/rediscluster/7001/log/redis_7001.log"#g' /home/rediscluster/7001/conf/redis.conf

sed -i 's#dbfilename dump.rdb#dbfilename dump-7001.rdb#g' /home/rediscluster/7001/conf/redis.conf

sed -i 's#dir ./#dir "/home/rediscluster/7001/data/"#g' /home/rediscluster/7001/conf/redis.conf


#vim /home/rediscluster/7001/conf/redis.conf

masterauth "1234"   #设置密码，redis启用密码认证一定要requirepass和masterauth同时设置；masterauth作用：主要是针对master对应的slave节点设置的，在slave节点数据同步的时候用到。requirepass作用：对登录权限做限制，redis每个节点的requirepass可以是独立、不同的。requirepass验证客户端，masterauth验证从库。

requirepass "1234"  

cluster-enabled yes

cluster-node-timeout 15000
```



#### 目录的配置文件拷贝及修改

将7001目录的配置文件拷贝到7002-7002实例并注意将配置文件的7001改为7001-7002：

```shell
192.168.6.132 主机复制文件
cp /home/rediscluster/7001/conf/redis.conf  /home/rediscluster/7002/conf/
sed -i 's#7001#7002#g' /home/rediscluster/7002/conf/redis.conf
192.168.6.137 主机复制文件
scp /home/rediscluster/7001/conf/redis.conf root@192.168.6.137 /home/rediscluster/7001/conf
```

#### 环境变量配置

```shell
echo 'export  REDIS_HOME=/home/redis-6.0.9' >> /etc/profile 

echo 'export  PATH=$REDIS_HOME/bin:$PATH' >> /etc/profile

source /etc/profile
```

#### 启动redis

```sh
redis-server /home/rediscluster/7001/conf/redis.conf
redis-server /home/rediscluster/7002/conf/redis.conf
```

#### 创建redis集群

```shell
/home/redis-6.0.9/bin/redis-cli --cluster create 192.168.6.132:7001 192.168.6.132:7002 192.168.6.137:7001 192.168.6.137:7002 192.168.6.138:7001 192.168.6.138:7002  -a "1234" --cluster-replicas 1

#回车即可 yes
```

#### 验证redis集群

集群创建成功后，登录redis验证，注意加上集群参数 -c：

```
 #登录redis集群
 /home/redis-6.0.9/bin/redis-cli -p 7001 -a 1234 -c -h 192.168.6.132
 #查看集群节点
/home/redis-6.0.9/bin/redis-cli -p 7001 -a 1234  -h 192.168.6.132 cluster nodes | grep master
#查看集群信息
/home/redis-6.0.9/bin/redis-cli -p 7001 -a 1234  -h 192.168.6.132 cluster info 


```

### redis开机自启

```shell
vim /etc/systemd/system/redis7001.service

[Unit]
Description=redis7001-server
After=network.target

[Service]
Type=forking
ExecStart=/home/redis-6.0.9/bin/redis-server /home/rediscluster/7001/conf/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```



```
--设置redis7001.service 开机自启动
systemctl daemon-reload
systemctl enable redis7001.service
systemctl start redis7001.service

ps -ef |grep redis
```



```shell
vim /etc/systemd/system/redis7002.service

[Unit]
Description=redis7002-server
After=network.target

[Service]
Type=forking
ExecStart=/home/redis-6.0.9/bin/redis-server /home/rediscluster/7002/conf/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

```
--设置redis7002.service 开机自启动
systemctl daemon-reload
systemctl enable redis7002.service
systemctl start redis7002.service

ps -ef |grep redis
```



## redis配置文件参数说明

```
1. Redis默认不是以守护进程的方式运行，可以通过该配置项修改，使用yes启用守护进程

daemonize no

2. 当Redis以守护进程方式运行时，Redis默认会把pid写入/var/run/redis.pid文件，可以通过pidfile指定

pidfile /var/run/redis.pid

3.指定Redis监听端口，默认端口为6379，作者在自己的一篇博文中解释了为什么选用6379作为默认端口，因为6379在手机按键上MERZ对应的号码，而MERZ取自意大利歌女Alessia Merz的名字

port 6379

4. 绑定的主机地址

bind 127.0.0.1

5.当 客户端闲置多长时间后关闭连接，如果指定为0，表示关闭该功能  

timeout 300
   
6. 指定日志记录级别，Redis总共支持四个级别：debug、verbose、notice、warning，默认为verbose

loglevel verbose

7. 日志记录方式，默认为标准输出，如果配置Redis为守护进程方式运行，而这里又配置为日志记录方式为标准输出，则日志将会发送给/dev/null

logfile stdout

8. 设置数据库的数量，默认数据库为0，可以使用SELECT <dbid>命令在连接上指定数据库id

databases 16

9. 指定在多长时间内，有多少次更新操作，就将数据同步到数据文件，可以多个条件配合

save <seconds> <changes>

Redis默认配置文件中提供了三个条件：

save 900 1

save 300 10

save 60 10000

分别表示900秒（15分钟）内有1个更改，300秒（5分钟）内有10个更改以及60秒内有10000个更改。

10. 指定存储至本地数据库时是否压缩数据，默认为yes，Redis采用LZF压缩，如果为了节省CPU时间，可以关闭该选项，但会导致数据库文件变的巨大

rdbcompression yes

11. 指定本地数据库文件名，默认值为dump.rdb

dbfilename dump.rdb

12. 指定本地数据库存放目录

dir ./

13. 设置当本机为slav服务时，设置master服务的IP地址及端口，在Redis启动时，它会自动从master进行数据同步

slaveof <masterip> <masterport>

14. 当master服务设置了密码保护时，slav服务连接master的密码

masterauth <master-password>

15. 设置Redis连接密码，如果配置了连接密码，客户端在连接Redis时需要通过AUTH <password>命令提供密码，默认关闭

requirepass foobared

16. 设置同一时间最大客户端连接数，默认无限制，Redis可以同时打开的客户端连接数为Redis进程可以打开的最大文件描述符数，如果设置 maxclients 0，表示不作限制。当客户端连接数到达限制时，Redis会关闭新的连接并向客户端返回max number of clients reached错误信息

maxclients 128

17. 指定Redis最大内存限制，Redis在启动时会把数据加载到内存中，达到最大内存后，Redis会先尝试清除已到期或即将到期的Key，当此方法处理 后，仍然到达最大内存设置，将无法再进行写入操作，但仍然可以进行读取操作。Redis新的vm机制，会把Key存放内存，Value会存放在swap区

maxmemory <bytes>

18. 指定是否在每次更新操作后进行日志记录，Redis在默认情况下是异步的把数据写入磁盘，如果不开启，可能会在断电时导致一段时间内的数据丢失。因为 redis本身同步数据文件是按上面save条件来同步的，所以有的数据会在一段时间内只存在于内存中。默认为no

appendonly no

19. 指定更新日志文件名，默认为appendonly.aof

 appendfilename appendonly.aof

20. 指定更新日志条件，共有3个可选值： no：表示等操作系统进行数据缓存同步到磁盘（快） always：表示每次更新操作后手动调用fsync()将数据写到磁盘（慢，安全） everysec：表示每秒同步一次（折衷，默认值）

appendfsync everysec

21.指定是否启用虚拟内存机制，默认值为no，简单的介绍一下，VM机制将数据分页存放，由Redis将访问量较少的页即冷数据swap到磁盘上，访问多的页面由磁盘自动换出到内存中（在后面的文章我会仔细分析Redis的VM机制）

vm-enabled no

22. 虚拟内存文件路径，默认值为/tmp/redis.swap，不可多个Redis实例共享

 vm-swap-file /tmp/redis.swap

23. 将所有大于vm-max-memory的数据存入虚拟内存,无论vm-max-memory设置多小,所有索引数据都是内存存储的(Redis的索引数据 就是keys),也就是说,当vm-max-memory设置为0的时候,其实是所有value都存在于磁盘。默认值为0

 vm-max-memory 0

24. Redis swap文件分成了很多的page，一个对象可以保存在多个page上面，但一个page上不能被多个对象共享，vm-page-size是要根据存储的 数据大小来设定的，作者建议如果存储很多小对象，page大小最好设置为32或者64bytes；如果存储很大大对象，则可以使用更大的page，如果不 确定，就使用默认值

 vm-page-size 32

25. 设置swap文件中的page数量，由于页表（一种表示页面空闲或使用的bitmap）是在放在内存中的，，在磁盘上每8个pages将消耗1byte的内存。

 vm-pages 134217728

26.设置访问swap文件的线程数,最好不要超过机器的核数,如果设置为0,那么所有对swap文件的操作都是串行的，可能会造成比较长时间的延迟。默认值为4

 vm-max-threads 4

27. 设置在向客户端应答时，是否把较小的包合并为一个包发送，默认为开启

glueoutputbuf yes

28. 指定在超过一定的数量或者最大的元素超过某一临界值时，采用一种特殊的哈希算法

hash-max-zipmap-entries 64

hash-max-zipmap-value 512

29. 指定是否激活重置哈希，默认为开启（后面在介绍Redis的哈希算法时具体介绍）

activerehashing yes

30. 指定包含其它的配置文件，可以在同一主机上多个Redis实例之间使用同一份配置文件，而同时各个实例又拥有自己的特定配置文件

include /path/to/local.conf

```

















