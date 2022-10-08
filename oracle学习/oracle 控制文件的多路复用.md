# 				oracle 控制文件的多路复用

#### 一、概念：

控制文件是Oracle数据库非常重要的文件，记录了当前数据库的结构信息,同时也包含数据文件及日志文件的信息以及相关的状态,归档信息等等，一个数据库至少有一个控制文件，强烈的建议超过一个控制文件，每个控制文件的备份应该放在不同的磁盘上。

#### 二、配置步骤：

##### 1.创建存放多路复用控制文件的目录(windows手工动创建)

##### 2.查看现有的控制文件

```
show parameter contro;
```

##### 3添加control03.ctl

```
alter system set control_files='D:\app\Administrator\oradata\orcl\control01.ctl','D:\app\Administrator\flash_recovery_area\orcl\control02.ctl','D:\flash_recovery_area\controfile\control03.ctl' scope=spfile;
```

##### 4.关闭数据库

```
shutdown immediate
```

##### 5.拷贝control01.ctl到/flash_recover_area/controfile/目录下并且重命名control03.ctl

##### 6.启动数据库，查看控制文件个数

```
启动数据库
startup
查看控制文件个数
show parameter contro;
```



#### 三、控制文件备份

##### 1.RMAN自动备份控制文件

```
进入rman 控制台
rman target /
启用控制文件自动备份参数
RMAN>configure controlfile autobackup on;
配置控制文件自动备份路径及格式
RMAN>configure controlfile autobackup format for device type disk to'D:\flash_recovery_area\controfile\ctl_%F';
查看备份的控制文件
RMAN> LIST BACKUP OF CONTROLFILE;

```

##### 2.RMAN手动备份控制文件

```
进入rman 控制台
rman target /
手动备份控制文件
方法一：
RMAN>BACKUP CURRENT CONTROLFILE;
方法二：
RMAN>BACKUP CURRENT CONTROLFILE FORMAT 'D:\flash_recovery_area\controfile/ctl_%d_%T_%s_%p.bak';
方法三：
RMAN>BACKUP AS COPY CURRENT CONTROLFILE FORMAT 'D:\flash_recovery_area\controfile\ctl.bak';
查看备份的控制文件
RMAN> LIST BACKUP OF CONTROLFILE;
```





https://blog.51cto.com/lhrbest/2702976