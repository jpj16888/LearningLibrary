### 								Oracle更改redo log大小 or 增加redo log组

#### 1.redo log介绍

```
Oracle的数据库日志称为redo log，所有数据改变都记录redo log，可以用于修复受损的数据库。Redo日志是分组的，默认是三组。Redo日志是轮流使用的，一个redo log满了，LGWR会切换到下一组redo log，这种操作称为log switch，做log switch的同时也会做checkpoint，相应的信息还会写入控制文件
```

#### 2.查看现有redolog的信息

```sql
 select * from v$log;
```

##### status 四个值的含义：

Unused – 表示还没被使用过
Current – 表示正在使用
Active – 日志处于活动状态，但不是当前日志。它是故障恢复所必需的
Inactive – 实例恢复不再需要日志

#### 3.查询redo表空间存放位置

```sql
select * from v$logfile;
```

**由于ORACLE没有提供类似RESIZE的参数来重新调整REDO LOG FILE的大小，故只能先把这个文件删除了，然后再重建。**
**又由于ORACLE要求最少有两组日志文件在用，所以不能直接删除，必须要创建中间过渡的REDO LOG日志组。**

#### 4、创建新的redo日志组

```sql
ALTER DATABASE ADD LOGFILE GROUP 11 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO011.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 12 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO012.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 13 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO013.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 14 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO014.LOG') SIZE 200M;
```

#### 5、切换当前日志到新的日志组

```SQL
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system archive log current;
```

#### 6、删除旧的日志组

通过select * from v$log;
**查看group 1/2/3上的redo状态为inactive后，方可执行如下命令。**

```
alter database drop logfile group 1;
alter database drop logfile group 2;
alter database drop logfile group 3;
```

**查看日志组的状态看一下哪个是当前组，哪个是inactive状态的，删除掉inactive的那个组；如果状态为current和active 在删除的时候会报错。**

#### 7、操作系统下删除原日志组1、2、3中的文件

注意：每一步删除drop操作，都需手工删除操作系统中的实体文件。

#### 8.重建日志组1、2、3、4

```SQL
ALTER DATABASE ADD LOGFILE GROUP 1 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO01.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 2 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO02.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 3 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO03.LOG') SIZE 200M;
ALTER DATABASE ADD LOGFILE GROUP 4 ('D:\APP\ADMINISTRATOR\ORADATA\ORCL\REDO04.LOG') SIZE 200M;
```

#### 9、切换日志组

多执行几次如下命令，同时通过select * from gv$log来观察5/6/7/8下的redo日志状态是不是为inactive；
查看日志组的状态看一下哪个是当前组，哪个是inactive状态的，删除掉inactive的那个组。如果状态为current和active 在删除的时候会报错。

```SQL
alter system switch logfile;
```

#### 10、删除中间过渡用的日志组11、12、13、14

```SQL
alter database drop logfile group 11;
alter database drop logfile group 12;
alter database drop logfile group 13;
alter database drop logfile group 14;
```

**到操作系统下删除原日志组11、12、13、14中的文件**

#### 11、备份当前的最新的控制文件

因日志组发生变化，建议备份一次controlfile文件。

```sql
 alter database backup controlfile to trace resetlogs;  --D:\app\Administrator\diag\rdbms\
```

