##                     oracle快速恢复区

#### 1.概念

是一个默认放置所有备份恢复操作有关文件的地方，包括：控制文件在线镜像、在线重做日志、归档日志、外来归档日志、控制文件镜像复制、数据文件镜像复制、RMAN备份片和闪回日志。
如果启用的快速恢复区，它就成了RMAN备份默认的去处，无论是RMAN备份片、镜像复制、还是控制文件自动备份，只要没有在RMAN配置或则backup命令中指明路径就全部进入快速恢复区。



#### 2.快速恢复区两个参数设置

DB_RECOVERY_FILE_DEST_SIZE	用于设置快速恢复区的大小。

DB_RECOVERY_FILE_DEST	用于设置快速恢复区的路径。

##### 快速恢复区参数设置步骤

```
SQLPLUS / AS SYSDBA;
1.查看快速恢复区的参数信息
show parameter db_recovery_file_dest;
2.修改快速恢复区的大小
SQL> alter system set db_recovery_file_dest_size=4G scope=spfile;

System altered.

3.修改快速恢复区的路径
SQL> alter system set db_recovery_file_dest='D:\archivelog' scope=spfile;

System altered.
4.安全关闭数据库
SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.

5.开启数据库
SQL> startup
ORACLE instance started.

Total System Global Area  830930944 bytes
Fixed Size            2257800 bytes
Variable Size          536874104 bytes
Database Buffers      285212672 bytes
Redo Buffers            6586368 bytes
Database mounted.
Database opened.

6.查看修改参数是否生效
SQL> show parameter db_recovery;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_recovery_file_dest                string     D:\archivelog
db_recovery_file_dest_size           big integer 4G
```



#### 3.reset快速恢复区(2个参数清空)

```
SQLPLUS / AS SYSDBA;
1.查看快速恢复区的参数信息
show parameter db_recovery_file_dest;
2.reset快速恢复区的大小
SQL> alter system reset db_recovery_file_dest_size scope=spfile sid='*';

System altered.

3.reset快速恢复区的路径
SQL> alter system reset db_recovery_file_dest scope=spfile sid='*';

System altered.

4.安全关闭数据库
SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.
5.开启数据库
SQL> startup
ORACLE instance started.

Total System Global Area  830930944 bytes
Fixed Size            2257800 bytes
Variable Size          536874104 bytes
Database Buffers      285212672 bytes
Redo Buffers            6586368 bytes
Database mounted.
Database opened.
6.查看修改参数是否生效
SQL> show parameter db_recovery

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_recovery_file_dest                string
db_recovery_file_dest_size           big integer 0
```

#### 4.查看快速恢复区的空间使用情况

```
可以通过数据字典v$recovery_file_dest来查看
select name,space_limit,space_used,number_of_files from v$recovery_file_dest;
```

#### 5.解决快速恢复区空间不足的问题（3种方法）

#####  1）重新设置快速恢复区的大小

```
  alter system set db_recovery_file_dest_size=5g;
```

#####  2)删除不需要的文件

使用CROSSCHECK和DELETE OBSOLETE指令删除不需要的文件，或者使用DELETE EXPIRED 指令删除那些不需要的备份文件。或者使用RMAN的BACKUP RECOVERY AREA指令将恢复区中的文件复制到磁带中。

#####  3）删除当前的恢复区，重新设置。

```
 alter system set db_recovery_file_dest='F:\archivelog';
```


