## elasticSearch集群搭建

[TOC]



#### 条件：需要安装JDK1.8及以上

参考地址：https://blog.csdn.net/kavito/article/details/88289820



#### 场景介绍

```
服务器A IP：192.168.6.132

服务器B IP：192.168.6.137

服务器C IP：192.168.6.138
```



### 三台服务器都执行

#### 下载解压安装包

访问elasticSearch官网地址 https://www.elastic.co/

下载指定版本的安装包：elasticsearch-6.6.0.tar.gz

```shell
cd /usr/local 
wget  https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.6.0.tar.gz
tar -zxvf elasticsearch-6.6.0.tar.gz 
```

#### 创建es账号

es 不能以root 运行，需要用其他账户运行

```shell
useradd es
passwd es
```

#### 创建数据日志存储路径

```shell
mkdir -p  /usr/local/es/data
mkdir -p  /usr/local/es/logs
```

#### 修改存储所有者

```shell
 chown -R es:es  /usr/local/elasticsearch-6.6.0
 chown -R es:es  /usr/local/es
```

#### 配置jvm参数

```shell
Elasticsearch基于Lucene的，而Lucene底层是java实现，因此我们需要配置jvm参数。
编辑jvm.options
vim /usr/local/elasticsearch-6.6.0/config/jvm.options

修改默认配置：-Xms1g    -Xmx1g为 
-Xms512m
-Xmx512m
```

#### 配置yml文件参数

###### node.name 这个值每台电脑配置需要不一样

```shell
vim /usr/local/elasticsearch-6.6.0/config/elasticsearch.yml
```

```yaml
# ======================== Elasticsearch Configuration =========================
#
# NOTE: Elasticsearch comes with reasonable defaults for most settings.
#       Before you set out to tweak and tune the configuration, make sure you
#       understand what are you trying to accomplish and the consequences.
#
# The primary way of configuring a node is via this file. This template lists
# the most important settings you may want to configure for a production cluster.
#
# Please consult the documentation for further information on configuration options:
# https://www.elastic.co/guide/en/elasticsearch/reference/index.html
#
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
#集群名称
cluster.name: myescluster
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#节点名称
node.name: node-1
#
# Add custom attributes to the node:
#
#node.attr.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#数据存储路径
path.data: /usr/local/es/data
#
# Path to log files:
#日志存储路径
path.logs: /usr/local/es/logs

#权限成为主节点
node.master: true
#读写磁盘
node.data: true
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
#bootstrap.memory_lock: true
#
# Make sure that the heap size is set to about half the memory available
# on the system and that the owner of the process is allowed to use this
# limit.
#
# Elasticsearch performs poorly when the system is swapping the memory.
#
# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#绑定的IP地址（0.0.0.0 说明都可以访问）
network.host: 0.0.0.0
#
# Set a custom port for HTTP:
#对外访问的http端口
http.port: 9200
#节点间交互的tcp端口，默认是9300
transport.tcp.port: 9300

# For more information, consult the network module documentation.
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when new node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#节点列表
discovery.zen.ping.unicast.hosts: ["192.168.6.132:9200", "192.168.6.137:9200","192.168.6.138:9200"]
#
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
#至少2个节点在线
discovery.zen.minimum_master_nodes: 2
#
# For more information, consult the zen discovery module documentation.
#
# ---------------------------------- Gateway -----------------------------------
#
# Block initial recovery after a full cluster restart until N nodes are started:
#
#gateway.recover_after_nodes: 3
#
# For more information, consult the gateway module documentation.
#
# ---------------------------------- Various -----------------------------------
#
# Require explicit names when deleting indices:
#
#action.destructive_requires_name: true

http.cors.enabled: true
http.cors.allow-origin: "*"
```

#### 报错处理

##### 错误1：

max file descriptors [4096] for elasticsearch process likely too low, increase to at least [65536]

```shell
su root 
并添加下面的内容： /etc/security/limits.conf

echo '* soft nofile 65536'  >> /etc/security/limits.conf
echo '* hard nofile 131072' >> /etc/security/limits.conf
echo '* soft nproc 4096'  >>   /etc/security/limits.conf
echo '* hard nproc 4096' >>   /etc/security/limits.conf
```

##### 错误2：

报错线程数不够：max number of threads [1024] for user [leyou] is too low, increase to at least [4096]

```shell
需要修改内存大小如下：
（注意20-nproc.conf 有可能不一样，*-nproc.conf）
cd /etc/security/limits.d/
vim 20-nproc.conf
将* soft nproc 1024改为

* soft nproc 4096  
```

##### 错误3:

max virtual memory areas vm.max_map_count [65530] likely too low, increase to at least [262144]

报错限制一个进程可以拥有的VMA(虚拟内存区域)的数量，错误如下：

```shell
需要修改：
/etc/sysctl.conf 
添加下面内容
 echo ' vm.max_map_count=655360' >> /etc/sysctl.conf 
完成后执行sysctl -p命令，载入sysctl配置文件;
sysctl -p
```

#### 运行 elasticsearch

```shell
su es 
cd /usr/local/elasticsearch-6.6.0/bin/
./elasticsearch
```

#### 网页运行测试

```shell
http://192.168.6.132:9200/_cluster/health?pretty
http://IP/_cluster/health?pretty
出现对应的json字符，证明成功
```

#### 设置开机启动

```
su root
vim  /etc/init.d/elasticsearch 
```

编写启动脚本

```
# !/bin/bash
#chkconfig: 345 63 37
#description: elasticsearch
#processname: elasticsearch
 
#【这个目录是你JAVA_HOME所在文件夹的目录】
export JAVA_HOME=/usr/local/java/jdk1.8.0_66
export JAVA_BIN=/usr/local/java/jdk1.8.0_66/bin
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH
 
export ES_HOME=/usr/local/elasticsearch-6.6.0
#【这个目录是你Es所在文件夹的目录】
 
case $1 in
        start)
                su es<<!  #【es 这个是启动es的账户，如果你的不是这个记得调整】
                cd $ES_HOME
                ./bin/elasticsearch -d
!
                echo "elasticsearch is started"
                ;;
        stop)
                es_pid=`ps aux|grep elasticsearch`
                kill -9 $es_pid
                echo "elasticsearch is stopped"
                ;;
        restart)
        		 pid=`cat $ES_HOME/pid`
    			 kill -9 $pid
                 echo "elasticsearch is stopped"
                 sleep 1
                 su - es -c "$ES_HOME/bin/elasticsearch -d -p pid"
!
                echo "elasticsearch is started"
        ;;
    *)
        echo "start|stop|restart"
        ;;
esac
exit 0
```

修改文件权限

```
chmod 777 /etc/init.d/elasticsearch
chown -R es:es /etc/init.d/elasticsearch
```

添加和删除服务并设置启动方式

```
# 添加系统服务
chkconfig --add elasticsearch
# 删除系统服务
chkconfig --del elasticsearch
```

关闭和启动服务

```
# 启动服务
service elasticsearch start
# 停止服务
service elasticsearch stop
# 重启服务
service elasticsearch restart
```

设置服务是否开机启动

```
# 开启开机自动启动服务
chkconfig elasticsearch on
# 关闭开机自动启动服务
chkconfig elasticsearch off
```

查看当前的开机启动服务命令

```
chkconfig --list
```

### 验证下服务是否正常运行

```
curl  http://127.0.0.1:9200
```



## kibana 安装



kibana下载地址：https://www.elastic.co/cn/downloads/past-releases/kibana-6-6-0
安装参考：https://blog.csdn.net/cb2474600377/article/details/78963247

#### 1.上传文件 

```shell
cd /usr/local

rz
```



#### 2.解压

```shell
tar -zxvf kibana-6.6.0-linux-x86_64.tar.gz
```

#### 3.修改配置文件

```shell
vim /usr/local/kibana-6.6.0-linux-x86_64/config/kibana.yml 

server.port: 5601

server.host: "192.168.6.200"

elasticsearch.hosts: ["http://192.168.6.132:9200"]
```

#### 4.启动

```shell
cd /usr/local/kibana-6.6.0-linux-x86_64/bin
./kibana
```



#### 5.设置开机启动

```
vim /etc/init.d/kibana
```

```
#!/bin/bash
#chkconfig: 345 63 37
#description: kibana
#processname:kibana-7.6.2

export KIBANA_HOME=/usr/local/kibana-6.6.0-linux-x86_64

case $1 in
        start)
                cd $KIBANA_HOME
                ./bin/kibana -p pid &
                exit
!
                echo "kibana is started"
                ;;
        stop)
                pid=`cat $KIBANA_HOME/pid`
                kill -9 $pid
                echo "kibana is stopped"
                ;;
        restart)
                pid=`cat $KIBANA_HOME/pid`
                kill -9 $pid
                echo "kibana is stopped"
                sleep 5
                cd $KIBANA_HOME
                ./bin/kibana -p pid &
                exit
!
                echo "kibana is started"
        ;;
    *)
        echo "start|stop|restart"
        ;;
esac
exit 0
```

```
修改文件权限

chmod 777 /etc/init.d/kibana
chown -R es:es /etc/init.d/kibana
# 添加系统服务
chkconfig --add kibana
# 删除系统服务
chkconfig --del kibana

关闭和启动服务

# 启动服务
service kibana start
# 停止服务
service kibana stop
# 重启服务
service kibana restart

设置服务是否开机启动

# 开启开机自动启动服务
chkconfig kibana on
# 关闭开机自动启动服务
chkconfig kibana off

查看当前的开机启动服务命令
chkconfig --list


```



## ik分词器

下载地址：https://github.com/medcl/elasticsearch-analysis-ik/releases

参考：https://zq99299.github.io/note-book/elasticsearch-senior/ik/30-ik-introduce.html

#### 安装

```shell
#1.切换目录到es插件目录
cd /usr/local/elasticsearch-6.6.0/plugins
#2.创建ik目录
mkdir ik
3.#上传安装包
cd ik/
rz
4.解压安装包
unzip elasticsearch-analysis-ik-6.6.0.zip
5.重启es
```

#### ik 分词器基础知识

```
两种 analyzer，你根据自己的需要自己选吧，但是一般是选用 ik_max_word

ik_max_word 会将文本做最细粒度的拆分

比如会将「中华人民共和国国歌」拆分为：中华人民共和国、中华人民、中华、华人、人民共和国、人民、人、民、共和国、共和、和、国国、国歌，会穷尽各种可能的组合；

ik_smart 最粗粒度的拆分

比如会将「中华人民共和国国歌」拆分为：中华人民共和国、国歌。

显而易见在搜索效果中来说，拆分越细粒度的搜索效果越好，比如搜索「共和国」在「中华人民共和国、国歌」索引中能搜索到吗？
```

####  语法验证ik

```json
GET /_analyze
{
  "text": "中华人民共和国国歌",
  "analyzer": "ik_smart"
}
```

#### 响应结果

```json
{
  "tokens": [
    {
      "token": "中华人民共和国",
      "start_offset": 0,
      "end_offset": 7,
      "type": "CN_WORD",
      "position": 0
    },
    {
      "token": "国歌",
      "start_offset": 7,
      "end_offset": 9,
      "type": "CN_WORD",
      "position": 1
    }
  ]
}
```

## head 插件安装

安装参考：  https://blog.csdn.net/Pointer_Sky/article/details/107788422

nodejs 下载地址：https://nodejs.org/zh-cn/download/

elasticsearch-head下载地址：https://github.com/mobz/elasticsearch-head

```sh
#安装依赖
yum -y install gcc gcc-c++ openssl-devel
#1.文件上传 rz
#2.解压
tar -zxvf node-v16.14.0-linux-x64.tar.gz /opt
mv node-v16.14.0-linux-x64 node

#3.环境变量配置
vim /etc/profile
export NODE_HOME=/opt/node  
export PATH=$NODE_HOME/bin:$PATH
#重新加载配置文件
source/etc/profile 

4.#检查nodejs 是否成功
node -v 
#看到版本证明安装成功

5.#cnpm安装
npm install -g cnpm --registry=https://registry.npm.taobao.org

6.#安装 grunt
#grunt是一个很方便的构建工具，可以进行打包压缩、测试、执行等等的工作，6.0里的head插件就是通过grunt启动的。因此需要安装一下grunt：
cnpm install -g grunt-cli
cnpm install grunt --save-dev

#完成之后，执行 grunt -version 查看是否安装成功。

#附Grunt常用插件说明：
#1)grunt-contrib-uglify：压缩js代码
#2)grunt-contrib-concat：合并js文件
#3)grunt-contrib-qunit：单元测试
#4)grunt-contrib-jshint：js代码检查
#5)grunt-contrib-watch：文件监控
#6)grunt-contrib-sass：Scss编译
#7)grunt-contrib-connect：建立本地服务器

7.#项目install
#rz上传 elasticsearch-head-master.zip
#解压
unzip elasticsearch-head-master.zip /opt
#在项目目录下执行
cd /opt/elasticsearch-head-master
cnpm install
 #如果按照过程中提示权限错误，可以使用命令：cnpm install --unsafe-perm

8.#修改Gruntfile.js 文件，大概在96行增加
hostname:'0.0.0.0',
9.#启动head插件服务：
cnpm run start
```



## logstash 安装

下载地址：https://www.elastic.co/cn/downloads/past-releases#logstash

logstash和elasticsearch的版本兼容性 查看：https://www.elastic.co/cn/support/matrix#matrix_compatibility

##### 1.上传压缩包到服务器

##### 2.解压

```sh
tar -zxvf logstash-6.6.0.tar.gz
```

##### 3.启动logstash

​	Logstash 的启动命令位于安装路径的 bin 目录中，直接运行 logstash 不行， 需要按如下方式提供参数:

```sh
./logstash -e "input {stdin {}} output {stdout{}}"
```

启动时应注意: -e 参数后要使用双引号。如果在命令行启动日志中看到 “Successfully started Logstash API end-point l:port= >9600”，就证明启动成功。这个启动过程会非常慢，需要耐心等待。



在默认情况下，stdout 输出插件的编解码器为 rubydebug,所以输出内容中 包含了版本、时间等信息，其中 message 属性包含的就是在命令行输入的内容。 试着将输出插件的编码器更换为 plain 或 line，则输入的结果将会发生变化:

```sh
./logstash -e "input {stdin {}} output {stdout{codec => plain}}"
```



配置文件的语法形式与命令行相同，要使用的插件是通过插件名称来指定。 例如，想要向 Elasticsearch 中发送数据，则应该使用名称为 elasticsearch 的输出插件。在Logstash 安装路径下的config目录中，有一个名为logstash-sample.conf 的文件，提供了配置插件的参考

##### 编写 std_es. conf 

```sh
input {
  stdin {
    
  }
}

output {
  elasticsearch {
    hosts => ["http://192.168.6.132:9200"]
    index => "mylogstash1"
    #user => "elastic"
    #password => "changeme"
  }
}

```

##### 启动 Logstash脚本文件 std_es. conf 

```sh
/opt/logstash-6.6.0/bin/logstash -f /opt/logstash-6.6.0/config/std_es.conf
```



### logstash收集数据存放elasticsearch

```
input {
          file{
        path => "/home/rediscluster/7001/log/redis_7001.log"
        start_position => "beginning"
        type => "redis7001"
    }

}
output {
       elasticsearch {
                        hosts => ["http://192.168.6.132:9200"]
                        index => "redis-systemlog-%{+YYYY.MM.dd}"
                                }
                        }
        }
```



### kafka安装

kafka 下载：https://mirrors.aliyun.com/apache/kafka/2.8.2/kafka_2.12-2.8.2.tgz?spm=a2c6h.25603864.0.0.304841a4iRSTVh

```sh
#1. jdk 安装 
#2.上传 
rz
#3.解压
tar -zxvf kafka_2.12-2.8.2.tgz -C /opt/
#注释zookeeper文件内容
sed -i 's/^[^#]/#&/'  /opt/kafka_2.12-2.8.2/config/zookeeper.properties
#4.修改 zookeeper 配置文件
vim /opt/kafka_2.12-2.8.2/config/zookeeper.properties
#ZK数据存放路径
Dirdata=/opt/zookeeper/data
#ZK日志存放路径
Dirlogs=/opt/zookeeper/logs
#客户端连接ZK服务器的端口  
clientPort=2181
#ZK服务器之间或客户端与服务器之间维持心跳的时间间隔 session的会话时间 以ms为单位
tickTime=2000
#服务器启动以后，master和slave通讯的时间
initLimit=20
#master和slave之间的心跳检测时间，检测slave是否存活
syncLimit=10
#配置的主机映射 2888是数据同步和消息传递端口，3888是选举端口
server.1=192.168.1.132:2888:3888
server.2=192.168.1.137:2888:3888
server.3=192.168.1.138:2888:3888


#5.创建zookeeper data,logs 文件路径
mkdir -p /opt/zookeeper/{data,logs}

#6.创建myid文
#第一台（192.168.1.132）
echo 1 > /opt/zookeeper/data/myid
#第二台（192.168.1.137）
echo 2 > /opt/zookeeper/data/myid
#第三台（192.168.1.138）
echo 3 > /opt/zookeeper/data/myid

```

