## liunx安装mycat



参考文件：http://www.360doc.com/content/22/0506/15/65840191_1030032187.shtml

#### 1.安装jdk脚本

```sh
#!/bin/bash

jdkTargz="/opt/tools/jdk-8u66-linux-x64.tar.gz"

# 检查原先是否已配置java环境变量
checkExist(){
 jdk1=$(grep -n "export JAVA_HOME=.*" /etc/profile | cut -f1 -d':')
    if [ -n "$jdk1" ];then
        echo "JAVA_HOME已配置，删除内容"
        sed -i "${jdk1}d" /etc/profile
    fi
 jdk2=$(grep -n "export CLASSPATH=.*$JAVA_HOME.*" /etc/profile | cut -f1 -d':')
    if [ -n "$jdk2" ];then
        echo "CLASSPATH路径已配置，删除内容"
        sed -i "${jdk2}d" /etc/profile
    fi
 jdk3=$(grep -n "export PATH=.*$JAVA_HOME.*" /etc/profile | cut -f1 -d':')
    if [ -n "$jdk3" ];then
        echo "PATH-JAVA路径已配置，删除内容"
        sed -i "${jdk3}d" /etc/profile
    fi
}

# 查询是否有jdk.tar.gz
if [ -e $jdkTargz ];
then

echo "― ― 存在jdk压缩包 ― ―"
 echo "正在解压jdk压缩包..."
 tar -zxvf $jdkTargz -C /opt/tools
 if [ -e "/usr/local/java" ];then
 echo "存在该文件夹，删除..."
 rm -rf /usr/local/java
 fi
 echo "---------------------------------"
 echo "正在建立jdk文件路径..."
 echo "---------------------------------"
 mkdir -p /usr/local/java/
 mv /opt/tools/jdk1.8.0_66 /usr/local/java/java8
 # 检查配置信息
 checkExist 
 echo "---------------------------------"
 echo "正在配置jdk环境..."
 sed -i '$a export JAVA_HOME=/usr/local/java/java8' /etc/profile
 sed -i '$a export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' /etc/profile
 sed -i '$a export PATH=$PATH:$JAVA_HOME/bin' /etc/profile
 echo "---------------------------------"
 echo "JAVA环境配置已完成..."
 echo "---------------------------------"
  echo "正在重新加载配置文件..."
  echo "---------------------------------"
  source /etc/profile
  echo "配置版本信息如下："
  java -version
else
 echo "未检测到安装包，请将安装包放到/opt/tools目录下"
fi

```

#### 2.安装mycat

```sh
解压文件到/usr/local文件夹下
 tar -zxvf  Mycat-server-1.6.7.6-release-20220524173810-linux.tar.gz -C /usr/local
配置环境变量
vim /etc/profile
添加如下配置信息：
export MYCAT_HOME=/usr/local/mycat
export PATH=$MYCAT_HOME/bin:$PATH:$JAVA_HOME/bin
重新加载配置文件
source /etc/profile
```

### 安装Keepalived

##### 安装编译依赖包

```sh
yum install -y gcc openssl-devel libnl libnl-devel libnfnetlink-devel
```

##### 安装Keepalived

```sh
#解压keepalived压缩包放到/usr/local/并重命名为keepalived
cd /usr/local/src
tar -zxvf keepalived-2.0.7.tar.gz
mv keepalived-2.0.7 /usr/local/keepalived
 
#配置keepalived 得到一个Makefile的文件夹
#--prefix：keepalived安装目录
#--sysconf：keepalived的核心配置文件，必须要在/etc目录下面，改为其他位置会导致启动不了，不配置在该目录下的话，启动keepalived时日志文件里面会报错，显示找不到/etc这个文件夹
cd /usr/local/keepalived
./configure --prefix=/usr/local/keepalived/ --sysconf /etc
 
#编译和安装keepalived
make && make install
 
#创建keepalived软链接 /usr/sbin/如果存在keepalived就先删除
ln -s  /usr/local/keepalived/sbin/keepalived /usr/sbin/
 
#复制keepalived脚本文件到/etc/init.d/目录下
cd keepalived
cp /usr/local/keepalived/etc/init.d/keepalived /etc/init.d/
 
#设置Keepalived开机自启动
chkconfig --add keepalived
chkconfig keepalived on
 
#启动keepalived
service keepalived start
```



### mycat 配置Keepalived

##### 1、编辑keepalived配置文件

```sh
vi /etc/keepalived/keepalived.conf
```

##### 2、主服务器添加对应配置文件

```sh
global_defs {
	router_id LVS_LEVEL1	#主服务器名称
}

vrrp_script check_run {
   script "/etc/keepalived/mycat_check.sh"
   interval 5				#5秒执行一次脚本
}

vrrp_instance VI_1 {
    state MASTER			#主服务器
    interface eth0			#承载VIP地址到物理接口
    virtual_router_id 51	#虚拟路由器ID号，每个热播组保持一致
    priority 100			#优先级，数值越大优先级越高
    advert_int 1			#检查间隔，默认为1s
    authentication {		#认证信息，每个热播组保持一致
        auth_type PASS      #认证类型
        auth_pass 1111		#密码字串
    }
    virtual_ipaddress {
        192.168.0.144		#VIP地址（内网地址）
    }
    track_script {
        check_run
    }
}
```

##### 3、备份服务器添加对应配置文件

```sh
global_defs {
	router_id LVS_LEVEL2	#备份服务器名称
}
vrrp_script check_run {
	script "/etc/keepalived/mycat_check.sh"
	interval 5				#5秒执行一次脚本
}
vrrp_instance VI_1 {
    state BACKUP			#备份服务器
    interface eth0			#承载VIP地址到物理接口
    virtual_router_id 51	#虚拟路由器ID号，每个热播组保持一致
    priority 50				#优先级，数值越大优先级越高
    advert_int 1			#检查间隔，默认为1s
    authentication {		#认证信息，每个热播组保持一致
        auth_type PASS      #认证类型
        auth_pass 1111		#密码字串
    }
    virtual_ipaddress {
        192.168.0.144       #VIP地址（和主服务器设置一样）
    }
    track_script {
        check_run
    }
}
```

##### 4.mycat_check.sh

```sh
#!/bin/bash
/usr/bin/mysql -uroot -p'你自己的数据库密码' -e "show status" &>/dev/null 
if [ $? -ne 0 ] ;then
    systemctl stop keepalived
fi
```

```shell
chmod +x /etc/keepalived/mycat_check.sh
```

##### 5、重启keepalived 

```sh
service keepalived restart
```





### mycat配置连接信息

##### Mycat的server.xml配置逻辑库

```xml
<user name="root">
    <property name="password">123456</property>
	<property name="schemas">TESTDB</property>
</user>

<user name="readOnly">
	<property name="password">123456</property>
	<property name="schemas">TESTDB</property>
	<property name="readOnly">true</property>
</user>
```


配置说明：

user标签的name指的是应用连接中间件逻辑库的用户名
property标签的password指的是应用连接中间件逻辑库的密码
property标签的schemas指的是数据库配置文件schema.xml里<schemas>标签的name，可以配置一个或多个
property标签的readOnly指的是应用连接中间件逻辑库具有的权限，true为只读，false为读写，默认为false



### 配置数据库信息

#####  Mycat的schema.xml配置数据库信息

```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
    <!-- <schema name="park" checkSQLschema="false" sqlMaxLimit="100">
        <table name="part" dataNode="dn1,dn2,dn3,dn4" rule="sharding-by-month" />
    </schema> -->
	<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">  
    </schema>
	<dataNode name="dn1" dataHost="localhost1" database="test" />
    <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1" writeType="0" dbType="mysql" dbDriver="native" switchType="1" slaveThreshold="5">
    <heartbeat>show slave status</heartbeat>
    <!-- can have multi write hosts -->
    <writeHost host="hostM1" url="localhost:3306" user="root" password="root">
        <!-- can have multi read hosts -->
        <readHost host="hostS1" url="localhost:3307" user="root" password="root" />
    </writeHost>
    <writeHost host="hostM2" url="localhost:3308" user="root" password="root"></writeHost>
    </dataHost>
</mycat:schema>
```

配置说明：

dataHost标签的maxCon指的是每个读写实例连接池的最大连接。也就是说，标签内嵌套的writeHost、readHost标签都会使用这个属性的值来实例化出连接池的最大连接数

dataHost标签的minCon指的是每个读写实例连接池的最小连接，初始化连接池的大小

dataHost标签的balance指的是负载均衡类型，目前的取值有三种：

balance="0"，不开启读写分离机制，所有读操作都发送到当前可用的writeHost上
balance="1"，全部的readHost与stand by writeHost参与select语句的负载均衡，简单的说，当双主双从模式(M1->S1，M2->S2，并且M1与M2互为主备)，正常情况下，M2,S1,S2都参与select语句的负载均衡
balance="2"，所有读操作都随机的在writeHost、readhost上分发
balance="3"，所有读请求随机的分发到wiriterHost对应的readhost执行，writerHost不负担读压力，注意balance=3只在1.4及其以后版本有，1.3没有
dataHost标签的writeType指的是写类型，目前的取值有三种：

writeType="0"，所有写操作发送到配置的第一个writeHost，第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为准，切换记录在配置文件中:dnindex.properties
writeType="1"，所有写操作都随机的发送到配置的writeHost，1.5以后废弃不推荐
writeType="2"，不执行写操作
dataHost标签的switchType指的是自动切换类型，目前的取值有四种：

switchType="-1"，表示不自动切换
switchType="1"，默认值，自动切换
switchType="2"，基于MySQL主从同步的状态决定是否切换
switchType="3"，基于MySQLgalarycluster的切换机制（适合集群）（1.4.1）
第一台写入数据库hostM1宕机后，根据switchType=1会自动切换到hostM2上，当hostM1重启恢复之后，Mycat并不会切换回第一个hostM1写入节点，而是需要重新配置主从状态（Mycat没办法做到像Keeplived那样动态切换，其实Keeplived也可以实现读写分离，实现方式是通过配置两个虚拟IP，一个用来读另一个用来写，但是这种实现方式在代码层面依旧需要配置双数据源），或者把hostM2再关闭下，它就会自动切换回hostM1了

dataHost标签的dbType指的是数据库类型

指定连接的数据库类型，目前支持二进制的mysql协议，还有其他使用JDBC连接的数据库，例如：mongodb、oracle、spark等

dataHost标签的dbDriver指的是连接数据库的驱动

目前可选的值有native和JDBC

native：因为这个值执行的是二进制的mysql协议，所以可以使用mysql和maridb。其他类型的数据库则需要使用JDBC驱动来支持。从1.6版本开始支持postgresql的native原始协议
JDBC：需要将符合JDBC 4标准的驱动JAR包放到MYCAT\lib目录下，并检查驱动JAR包中包括如下目录结构的文件：META-INF\services\java.sql.Driver。在这个文件内写上具体的Driver类名，例如：com.mysql.jdbc.Driver
heartbeat标签指的是用于和数据库进行心跳检查的语句。例如，MYSQL可以使用select user()，Oracle可以使用select 1 from dual等。这个标签还有一个connectionInitSql属性，主要是当使用Oracla数据库时，需要执行的初始化SQL语句就这个放到这里面来。例如：



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

