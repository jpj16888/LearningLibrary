# mysql 两主两从配置



参考文件：https://blog.csdn.net/weixin_47354082/article/details/123769840

​                   https://blog.csdn.net/weixin_45881674/article/details/126444600



### 原理

将主结点中binlog日志内容，实时传送到相邻结点relay log中，再在各主从数据库进行SQL重放，实现数据一致，主主之间互为主从，两主结点表中数据会同时有写操作，确保不产生唯一性约束冲突；

### 主要问题

解决唯一性约束冲突，数据表定义自增长字段，一主结点奇数增长，一主结点偶数增长，也可应用程序算法实现，或引入第三方软件实现，只要能解决两主结点写操作不产生唯一性约束冲突；

### 架构

![img](https://img-blog.csdnimg.cn/ab1b113818e141fcb2e26a90ec79e1d0.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2VpeGluXzQ3MzU0MDgy,size_16,color_FFFFFF,t_70,g_se,x_16)

### 环境

| 主机    | IP            | 类型 | server id |
| ------- | ------------- | ---- | --------- |
| mysql_1 | 192.168.6.201 | 主1  | 201       |
| mysql_2 | 192.168.6.202 | 主2  | 202       |
| mysql_3 | 192.168.6.203 | 从1  | 203       |
| mysql_4 | 192.168.6.204 | 从2  | 204       |



### 安装MySQL

```sh
#mysql 下载地址
https://downloads.mysql.com/archives/community/

https://mirrors.aliyun.com/mysql/

https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.35-el7-x86_64.tar

#阿里云工具下载地址：
https://developer.aliyun.com/mirror/?spm=a2c6h.13651102.J_5404914170.37.2eaa1b115vVCF8&utm_content=g_1000283990


#检查  mariadb
rpm -qa | grep  mariadb
#删除mariadb 
yum remove mariadb-libs -y
#3.安装依赖
yum install -y gcc-c++ bison-devel  ncurses-devel  bison perl perl-devel   boost boost-devel boost-doc  libaio
#3.新建MySQL的软件目录、数据目录、日志目录
mkdir -p /database/ /data/mysql/ /log/mysql

cd /database/
#1.上传解压
rz
tar -zxvf mysql-5.7.35-el7-x86_64.tar.gz
mv mysql-5.7.35-el7-x86_64 mysql
#2.添加mysql组及用户
groupadd mysql
useradd -r -g mysql mysql  
chown -R  mysql:mysql /database/ /data/mysql/ /log/mysql

#修改环境变量
vim /etc/profile
export  PATH=/database/mysql/bin:$PATH
source /etc/profile

#安装
cd /database/mysql/bin/
./mysqld --initialize-insecure --user=mysql --datadir=/data/mysql --basedir=/database/mysql

#添加my.cnf配置文件
vim /etc/my.cnf
[mysqld]
user=mysql
port = 3306
basedir =  /database/mysql
datadir =  /data/mysql
socket =  /tmp/mysql.sock
default-character-set=utf8

[mysql]
socket =  /tmp/mysql.sock
default-character-set=utf8

#准备mysql 启动脚本
cd /database/mysql/support-files/
cp mysql.server /etc/init.d/mysqld

#启动
chkconfig --add mysqld
chkconfig mysqld on
service mysqld start

#设置mysql数据库root用户密码：
mysql -uroot -p   回车 密码为空
show databases;
use mysql;
update user set authentication_string=password(123456) where user="root";
#刷新权限（必须步骤）：
flush privileges;　

#设置远程连接
update user set host='%' where user='root' and host='localhost';
刷新权限（必须步骤）：flush privileges;　
quit;

#开启防火墙
systemctl start firewalld.service 
#把3306端口在防火墙里开启
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --reload 


```



### 主1-201：

```
[mysqld]
user=mysql
socket =  /tmp/mysql.sock
#设置3306端口
port = 3306 
# 设置mysql的安装目录
basedir=/database/mysql
# 设置mysql数据库的数据的存放目录
datadir=/data/mysql
# 允许最大连接数
max_connections=1000
# 服务端使用的字符集默认为UTF8
character-set-server=utf8
# 创建新表时将使用的默认存储引擎
default-storage-engine=INNODB
default-time_zone = '+8:00'    
#开启日志 
log-bin = mysql-bin
#设置服务id，主从不能一致  ,一般设置为ip最后一段
server-id = 201 
#设置需要同步的数据库 
binlog-do-db=test     
#屏蔽系统库同步 
binlog-ignore-db=mysql 
binlog-ignore-db=information_schema 
binlog-ignore-db=performance_schema

#以下为 双主双从 额外的配置
#表示在作为从机的时候，有写操作的时候也要更新二进制日志
log-slave-updates
#在主主同步配置时，需要将两台服务器的auto_increment_increment增长量都配置为2，
#而要把auto_increment_offset分别配置为1和2，这样才可以避免两台服务器同时做更新时自增长字段的值之间发生冲突。

#表示自增长字段每次递增的量，其默认值是1，取值范围是1 .. 65535
auto-increment-increment = 2   
#表示自增长字段从那个数开始，他的取值范围是1 .. 65535
auto-increment-offset = 1 


[mysql]
socket =  /tmp/mysql.sock
default-character-set=utf8

```



### 主2-202：

```
[mysqld]
user=mysql
socket =  /tmp/mysql.sock
#设置3306端口
port = 3306 
# 设置mysql的安装目录
basedir=/database/mysql
# 设置mysql数据库的数据的存放目录
datadir=/data/mysql
# 允许最大连接数
max_connections=1000
# 服务端使用的字符集默认为UTF8
character-set-server=utf8
# 创建新表时将使用的默认存储引擎
default-storage-engine=INNODB
default-time_zone = '+8:00'    
#开启日志 
log-bin = mysql-bin
#设置服务id，主从不能一致  ,一般设置为ip最后一段
server-id = 202
#设置需要同步的数据库 
binlog-do-db=test     
#屏蔽系统库同步 
binlog-ignore-db=mysql 
binlog-ignore-db=information_schema 
binlog-ignore-db=performance_schema


#以下为 双主双从 额外的配置
#表示在作为从机的时候，有写操作的时候也要更新二进制日志
log-slave-updates
#在主主同步配置时，需要将两台服务器的auto_increment_increment增长量都配置为2，
#而要把auto_increment_offset分别配置为1和2，这样才可以避免两台服务器同时做更新时自增长字段的值之间发生冲突。

#表示自增长字段每次递增的量，其默认值是1，取值范围是1 .. 65535
auto-increment-increment = 2   
#表示自增长字段从那个数开始，他的取值范围是1 .. 65535
auto-increment-offset = 2

[mysql]
socket =  /tmp/mysql.sock
default-character-set=utf8

```

### 从1-203：

```
[mysqld]
user=mysql
socket =  /tmp/mysql.sock
#设置3306端口
port = 3306 
# 设置mysql的安装目录
basedir=/database/mysql
# 设置mysql数据库的数据的存放目录
datadir=/data/mysql
# 允许最大连接数
max_connections=1000
# 服务端使用的字符集默认为UTF8
character-set-server=utf8
#从服务器唯一id
server-id=203
#启动中继日志
relay-log=mysql-relay

[mysql]
socket =  /tmp/mysql.sock
default-character-set=utf8
```

### 从2-204：

```
[mysqld]
user=mysql
socket =  /tmp/mysql.sock
#设置3306端口
port = 3306 
# 设置mysql的安装目录
basedir=/database/mysql
# 设置mysql数据库的数据的存放目录
datadir=/data/mysql
# 允许最大连接数
max_connections=1000
# 服务端使用的字符集默认为UTF8
character-set-server=utf8
#从服务器唯一id
server-id=204
#启动中继日志
relay-log=mysql-relay

[mysql]
socket =  /tmp/mysql.sock
default-character-set=utf8
```



### 创建同步账号并授权

创建主主同步账号repl_user和主从同步账号slave_sync_user。

#### 主1、主2 都需要执行：

```sql
CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
 
CREATE USER 'slave_sync_user'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
 
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
 
GRANT REPLICATION SLAVE ON *.* TO 'slave_sync_user'@'%';

```



#### 配置主主同步

#### 配置 主1->主2

##### 主1：

```sql
show master status;
+------------------+----------+--------------+--------------------------------------+---------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                     | Executed_Gtid_Set 
+------------------+----------+--------------+--------------------------------------+---------------+
| mysql-bin.000014 |     154 | test         | mysql,information_schema,performance_schema |                   

```

##### 主2

```sql
#复制主机
CHANGE MASTER TO MASTER_HOST='192.168.6.201', MASTER_USER='repl_user', MASTER_PASSWORD='123456', MASTER_LOG_FILE='mysql-bin.000014', MASTER_LOG_POS=154; 
#刷新
flush privileges;
#启动slave
start slave;
#查看slave 状态
show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.6.201
                  Master_User: repl_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000014
          Read_Master_Log_Pos: 154
               Relay_Log_File: mysql-1-relay-bin.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000014
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 529
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 201
                  Master_UUID: 9b13e93d-a6e4-11ed-9388-000c296b47ac
             Master_Info_File: /data/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version:
```



### 配置 主2->主1

##### 主2：

```
 show master status;
 
+------------------+----------+--------------+----------------------+-------+-------------------------
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                         Executed_Gtid_Set |
+------------------+----------+--------------+----------------------+---------+----------------------------
| mysql-bin.000006 |     154 | test         | mysql,information_schema,performance_schema |               |

```

##### 主1：

```sql
#复制主机
CHANGE MASTER TO MASTER_HOST='192.168.6.202', MASTER_USER='repl_user', MASTER_PASSWORD='123456', MASTER_LOG_FILE='mysql-bin.000006', MASTER_LOG_POS=154; 
#刷新
flush privileges;
#启动slave
start slave;
#查看slave 状态
show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.6.202
                  Master_User: repl_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000006
          Read_Master_Log_Pos: 154
               Relay_Log_File: mysql-1-relay-bin.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000006
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 529
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 202
                  Master_UUID: 8e007c0c-a6e4-11ed-8c1c-000c29e22264
             Master_Info_File: /data/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 



```



### 配置主从同步

##### 配置 主1->从1

##### 主1：

```
show master status;
+------------------+----------+--------------+--------------------------------------+------------------
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                     | Executed_Gtid_Set 
+------------------+----------+--------------+--------------------------------------+-------------------
| mysql-bin.000014 |     154 | test         | mysql,information_schema,performance_schema |           |                 
```

##### 从1：

```sql
#复制主机
CHANGE MASTER TO MASTER_HOST='192.168.6.201', MASTER_USER='slave_sync_user', MASTER_PASSWORD='123456', MASTER_LOG_FILE='mysql-bin.000014', MASTER_LOG_POS=154; 
#刷新
flush privileges;
#启动slave
start slave;
#查看slave 状态
show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.6.201
                  Master_User: slave_sync_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000014
          Read_Master_Log_Pos: 154
               Relay_Log_File: mysql-relay.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000014
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 523
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 201
                  Master_UUID: 9b13e93d-a6e4-11ed-9388-000c296b47ac
             Master_Info_File: /data/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 

```

### 配置 主2->从2

##### 主2：

```
show master status;
 
+------------------+----------+--------------+----------------------+-------+-------------------------
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                         Executed_Gtid_Set |
+------------------+----------+--------------+----------------------+---------+----------------------------
| mysql-bin.000006 |     154 | test         | mysql,information_schema,performance_schema |               |

```

##### 从2：

```sql
#复制主机
CHANGE MASTER TO MASTER_HOST='192.168.6.202', MASTER_USER='slave_sync_user', MASTER_PASSWORD='123456', MASTER_LOG_FILE='mysql-bin.000006', MASTER_LOG_POS=154; 
#刷新
flush privileges;
#启动slave
start slave;
#查看slave 状态

 show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.6.202
                  Master_User: slave_sync_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000006
          Read_Master_Log_Pos: 154
               Relay_Log_File: mysql-relay.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000006
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 523
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 202
                  Master_UUID: 8e007c0c-a6e4-11ed-8c1c-000c29e22264
             Master_Info_File: /data/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
```



### 验证双主双从同步效果

任意主结点操作数据，所有结点到得相同数据；

验证前检查，发现四个结点均只有4个自带数据库。

```
show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+

```

### 验证主1写入

##### 主1：

```sql
create database test;
use test;
create table books(id int primary key auto_increment, name varchar(50));
insert into books(name) values("MySQL5");
insert into books(name) values("Java");
insert into books(name) values("c++");

 select * from books;
+----+--------+
| id | name   |
+----+--------+
|  1 | MySQL5 |
|  3 | Java   |
|  5 | c++    |
+----+--------+
```

##### 主2、从1、从2

```sql
#查看数据库
show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test               |
+--------------------+
#切换数据库至test
use test;
#查看数据表
show tables;
+----------------+
| Tables_in_test |
+----------------+
| books          |
+----------------+

#查看表里面的数据
 select * from books;
+----+--------+
| id | name   |
+----+--------+
|  1 | MySQL5 |
|  3 | Java   |
|  5 | c++    |
+----+--------+

```



### 验证主2写入

##### 主2：

```sql
insert into books(name) values("Linux"),("UNIX"),("Windows"),("iOS");
select * from books;
+----+---------+
| id | name    |
+----+---------+
|  1 | MySQL5  |
|  3 | Java    |
|  5 | c++     |
|  6 | Linux   |
|  8 | UNIX    |
| 10 | Windows |
| 12 | iOS     |
+----+---------+
delete from books where id=3;
```



##### 主1、从1、从2：

```sql
select * from books;
+----+---------+
| id | name    |
+----+---------+
|  1 | MySQL5  |
|  3 | Java    |
|  5 | c++     |
|  6 | Linux   |
|  8 | UNIX    |
| 10 | Windows |
+----+---------+
```







### mysql清除主从复制关系

1. mysql主从复制中，需要将主从复制关系清除，需要取消其从库角色。这可通过执行RESET SLAVE ALL清除从库的同步复制信息、包括连接信息和二进制文件名、位置。从库上执行这个命令后，使用show slave status将不会有输出。
2. reset slave是各版本Mysql都有的功能，在stop slave之后使用。主要做：
3. 删除master.info和relay-log.info文件；
4. 删除所有的relay log（包括还没有应用完的日志），创建一个新的relay log文件；
5. 从Mysql 5.5开始，多了一个all参数。如果不加all参数，那么所有的连接信息仍然保留在内存中，包括主库地址、端口、用户、密码等。这样可以直接运行start slave命令而不必重新输入change master to命令，而运行show slave status也仍和没有运行reset slave一样，有正常的输出。但如果加了all参数，那么这些内存中的数据也会被清除掉，运行show slave status就输出为空了。

```sql
#停止从库
stop slave;  
#清除从库的同步复制信息
reset slave all;
#查看slave 状态
show slave status\G

#查看master 状态
show master status;
+------------------+----------+--------------+-------------------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                            | Executed_Gtid_Set |
+------------------+----------+--------------+------------------------------------+---------------+
| mysql-bin.000001 |      154 | test         | mysql,information_schema,performance_schema |                   
+------------------+----------+--------------+---------------------------------------+-------+----

#清除主库的同步复制信息
reset master;
#查看master 状态
show master status\G;

*************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 154
     Binlog_Do_DB: test
 Binlog_Ignore_DB: mysql,information_schema,performance_schema
Executed_Gtid_Set: 

```

 

### mycat 双主双从配置

##### 1.schema.xml配置

```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

	<schema name="test_rw" checkSQLschema="true" sqlMaxLimit="100" dataNode="dn1">
	<!--	
		<table name="" primaryKey="id" dataNode="dn1,dn2" rule="sharding-by-intfile" autoIncrement="true" fetchStoreNodeByJdbc="true">
			
		</table>
	-->
	</schema>
	
	<dataNode name="dn1" dataHost="dhost1" database="test" />
		<!--
 balance:负载均衡类型
balance=“0” 不开启读写分离机制，所有读操作都发送到当前可用的writeHost上
balance=“1”全部的readHost与stand by writeHost参与select语句的负载均衡，简单的说，当双主双从模式（M1-S1，M2-S2 并且M1 M2互为主备），正常情况下，M2,S1,S2都参与select语句的负载均衡。
balance=“2”所有读操作都随机的在writeHost、readHost上分发
balance=“3”：真正的读写分离所有读请求随机的分发到writeHst对应的readHost执行writeHost不负担读写压力。（1.4之后版本有） 

dataHost标签的writeType指的是写类型，目前的取值有三种：
writeType="0"，所有写操作发送到配置的第一个writeHost，第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为准，切换记录在配置文件中:dnindex.properties
writeType="1"，所有写操作都随机的发送到配置的writeHost，1.5以后废弃不推荐
writeType="2"，不执行写操作

dataHost标签的switchType指的是自动切换类型，目前的取值有四种：
switchType="-1"，表示不自动切换
switchType="1"，默认值，自动切换
switchType="2"，基于MySQL主从同步的状态决定是否切换
switchType="3"，基于MySQLgalarycluster的切换机制（适合集群）（1.4.1）

-->    
	<dataHost name="dhost1" maxCon="1000" minCon="10" balance="1" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1">
		<heartbeat>select user()</heartbeat>
		
		<writeHost host="master1" url="jdbc:mysql://192.168.6.201:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456">
			<readHost host="slave1" url="jdbc:mysql://192.168.6.203:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
		</writeHost>
		
		<writeHost host="master2" url="jdbc:mysql://192.168.6.202:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456">
			<readHost host="slave2" url="jdbc:mysql://192.168.6.202:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
		</writeHost>
	</dataHost>
		
</mycat:schema>
```

##### server.xml配置

```xml
<user name="root" defaultAccount="true">
		<property name="password">123456</property>
		<property name="schemas">test_rw</property> 
</user>
```





### mycat 一主一从配置

##### 1.schema.xml配置

```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

	<schema name="test_rw2" checkSQLschema="true" sqlMaxLimit="100" dataNode="dn1">
	<!--	
		<table name="" primaryKey="id" dataNode="dn1,dn2" rule="sharding-by-intfile" autoIncrement="true" fetchStoreNodeByJdbc="true">
			
		</table>
	-->
	</schema>
	
	<dataNode name="dn1" dataHost="dhost1" database="test" />
				<!-- balance:负载均衡类型
balance=“0” 不开启读写分离机制，所有读操作都发送到当前可用的writeHost上
balance=“1”全部的readHost与stand by writeHost参与select语句的负载均衡，简单的说，当双主双从模式（M1-S1，M2-S2 并且M1 M2互为主备），正常情况下，M2,S1,S2都参与select语句的负载均衡。
balance=“2”所有读操作都随机的在writeHost、readHost上分发
balance=“3”：真正的读写分离所有读请求随机的分发到writeHst对应的readHost执行writeHost不负担读写压力。（1.4之后版本有） 
dataHost标签的writeType指的是写类型，目前的取值有三种：
writeType="0"，所有写操作发送到配置的第一个writeHost，第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为准，切换记录在配置文件中:dnindex.properties
writeType="1"，所有写操作都随机的发送到配置的writeHost，1.5以后废弃不推荐
writeType="2"，不执行写操作

dataHost标签的switchType指的是自动切换类型，目前的取值有四种：
switchType="-1"，表示不自动切换
switchType="1"，默认值，自动切换
switchType="2"，基于MySQL主从同步的状态决定是否切换
switchType="3"，基于MySQLgalarycluster的切换机制（适合集群）（1.4.1）-->
    
	<dataHost name="dhost1" maxCon="1000" minCon="10" balance="1" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1">
		<heartbeat>select user()</heartbeat>
		
		<writeHost host="master1" url="jdbc:mysql://192.168.6.201:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456">
			<readHost host="slave1" url="jdbc:mysql://192.168.6.203:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
		</writeHost>
	</dataHost>
		
</mycat:schema>
```

##### server.xml配置

```xml
<user name="root" defaultAccount="true">
		<property name="password">123456</property>
		<property name="schemas">test_rw2</property> 
</user>
```

