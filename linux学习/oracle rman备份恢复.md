

# RMAN 备份与恢复 实例



参考：https://www.cnblogs.com/cinemaparadiso/p/16459115.html



1. #### 检查数据库模式：

   ```sql
   sqlplus  /as sysdba;
   #查看数据库是否处于归档模式中
   archive log list 
   #若为非归档,则修改数据库归档模式。
   
   shutdown immediate;
   
   startup mount;
   
   alter database archivelog;
   
   alter database force logging;
   
   alter database open;
   ```

   

#### 2.连接到target数据库

```sh
rman target / 
```



#### 3.查看有没有备份文件

```
list backupset
```

#### 4.常用备份命令：

##### 1.备份全库：

```sh
#备份全库及控制文件、服务器参数文件与所有归档的重做日志，并删除旧的归档日志
RMAN> backup database plus archivelog delete input;
```

##### 2.备份表空间：

```sh
#备份指定表空间及归档的重做日志，并删除旧的归档日志
RMAN> backup tablespace system plus archivelog delete input;
```

##### 3.备份归档日志：

```sh 
RMAN> backup archivelog all delete input;
```

##### 4.对整个数据库进行全备份(full backup)

```
backup database;
```

##### 5.查看参数

```
show all
```



rman中缺省的参数，可以通过 show all ;
来进行查看(RMAN configuration parameters),我们在使用backup database命令中，可以把这些default value 用固定的值来进行替代.

4.我们可以把备份的文件才备份的目录中拷贝到磁带上，然后删除备份目录下面的备份文件，如果下次需要恢复的话，只要把文件重新拷回到用来的备份目录就可以了
5.查看control file 文件中的备份信息(因为我们做的备份是在nocatalog模式下),control file 在/u01/oracle/oradata/ora10g目录下,由于control file 是个二进制文件，要查看control file 文件中的内容，用strings control03.ctl,发现control03.ctl中有rman备份的信息了


====================0级增量备份===============

概念：全备份和0级增量备份。全备份和0级增量备份几乎是一样的。唯一的区别，0级增量备份能作为增量备份的基础，而全备份不能作为增量备份的基础。其它方面完全一致

1.backup incremental level=0(leve 0) database;(增量为0的备份)
2.backup incremental level 1(level=1) database;(增量为1的备份)

在上面的备份中，我们备份了datafile,controlfile和parameter file.没有备份的文件有归档日志，重做日志和口令文件没有备份.口令文件不需要备份，我们用orapw来创建一个

新的口令文件.rman 在nocatalog模式下，不能够对redo log file 进行备份


===================备份archivelog 在nocatalog模式下=================

命令:backup database plus archivelog delete input(delete input的意思在备份完成后，删除 archivelog文件，这个选项可要可不要，这个命令也可以用 backup incremental level=0(1,2...)来进行备份)


=======================备份表空间====================

backup tablespace tablespacename

如果我们不知道tablespace的名字，在rman中，可要通过report schema命令，来查看表空间的名字

MAN> report schema;
Report of database schema

List of Permanent Datafiles
===========================
File Size(MB) Tablespace RB segs Datafile Name
---- -------- -------------------- ------- ------------------------
1 480 SYSTEM *** /home/oracle/oradata/ora10g/system01.dbf
2 25 UNDOTBS1 *** /home/oracle/oradata/ora10g/undotbs01.dbf
3 250 SYSAUX *** /home/oracle/oradata/ora10g/sysaux01.dbf
4 5 USERS *** /home/oracle/oradata/ora10g/users01.dbf
5 200 PERFSTAT *** /home/oracle/oradata/ora10g/perfstat.dbf

List of Temporary Files
=======================
File Size(MB) Tablespace Maxsize(MB) Tempfile Name
---- -------- -------------------- ----------- --------------------
1 20 TEMP 32767 /home/oracle/oradata/ora10g/temp01.dbf

 

========================备份控制文件====================

backup current controlfile

backup database include current controlfile

 

========================备份镜像========================

在rman的备份中有两种方式:备份集(backupset)和备份镜像(image copies).镜像备份主要是文件的拷贝:copy datafile ... to ...

我们在rman>report schema;

Report of database schema

List of Permanent Datafiles
===========================
File Size(MB) Tablespace RB segs Datafile Name
---- -------- -------------------- ------- ------------------------
1 480 SYSTEM *** /home/oracle/oradata/ora10g/system01.dbf
2 25 UNDOTBS1 *** /home/oracle/oradata/ora10g/undotbs01.dbf
3 250 SYSAUX *** /home/oracle/oradata/ora10g/sysaux01.dbf
4 5 USERS *** /home/oracle/oradata/ora10g/users01.dbf
5 200 PERFSTAT *** /home/oracle/oradata/ora10g/perfstat.dbf

List of Temporary Files
=======================
File Size(MB) Tablespace Maxsize(MB) Tempfile Name
---- -------- -------------------- ----------- --------------------
1 20 TEMP 32767 /home/oracle/oradata/ora10g/temp01.dbf

 

rman>copy datafile 5 to '/u01/rmanbak/tbso1bak.dbf';(copy 5 对应的schme:perfstat.dbf)

 

它会把tbs作为一个拷贝。我们用list backupset来看，不能够查看我们刚备份的 tbs01bak.dbf',因为它不是backupset. 我们用list copy 就能够查看我们刚才刚刚备份的文件


=======================单命令与批命令=================

单命令: backup database;

批命令:

rman> run{
2> allocate channel cha1 type disk;
3> backup
4> format '/u01/rmanbak/full_%t'
5> tag full-backup //标签可以顺便起，没关系
6> database;
7> release channel cha1;
8>}

这个run中有3条命令，分别用分号来进行分割.

format:
%c：备份片的拷贝数(从1开始编号)；
%d：数据库名称；
%D：位于该月中的天数(DD)；
%M：位于该年中的月份(MM)；
%F：一个基于DBID唯一的名称，这个格式的形式为c-xxx-YYYYMMDD-QQ,其中xxx位该数据库的DBID，YYYYMMDD为日期，QQ是一个1-256的序列；
%n：数据库名称，并且会在右侧用x字符进行填充，使其保持长度为8；
%u：是一个由备份集编号和建立时间压缩后组成的8字符名称。利用%u可以为每个备份集产生一个唯一的名称；
%p：表示备份集中的备份片的编号，从1开始编号；
%U：是%u_%p_%c的简写形式，利用它可以为每一个备份片段(既磁盘文件)生成一个唯一的名称，这是最常用的命名方式；
%t：备份集时间戳;
%T:年月日格式(YYYYMMDD);

channel的概念：一个channel是rman于目标数据库之间的一个连接，"allocate channel"命令在目标数据库启动一个服务器进程，同时必须定义服务器进程执行备份和恢复操作使

用的I/O类型

通道控制命令可以用来:
控制rman使用的OS资源
影响并行度
指定I/O带宽的限制值(设置 limit read rate 参数)
指定备份片大小的限制(设置 limit kbytes)
指定当前打开文件的限制值(设置 limit maxopenfiles)


=================================RMAN一周典型备份方案============================

1.星期天晚上 -level 0 backup performed(全备份)
2.星期一晚上 -level 2 backup performed
3.星期二晚上 -level 2 backup performed
4.星期三晚上 -level 1 backup performed
5.星期四晚上 -level 2 backup performed
6.星期五晚上 -level 2 backup performed
7.星期六晚上 -level 2 backup performed


如果星期二需要恢复的话，只需要1+2,
如果星期四需要恢复的话，只需要1+4,
如果星期五需要恢复的话，只需要1+4+5,
如果星期六需要恢复的话，只需要1+4+5+6.

 

自动备份:备份脚本+crontab
bakl0
bakl1
bakl2

执行脚本:
rman target / msglog=bakl0.log cmdfile=bakl0 (/表示需要连接的目标数据库,msglog表示日志文件，cmdfile表示的是脚本文件)
rman target / msglog=bakl1.log cmdfile=bakl1
rman target / msglog=bakl2.log cmdfile=bakl2

实例：rman target system/oracle@ora10g(/) msglog=/u01/rmanbak/bakl1.log cmdfile=/u01/rmanbak/bakl0


完整的命令:/u01/oracle/product/10.2.0/bin/rman target system/oracle@ora10g(/) msglog=/u01/rmanbak/bakl1.log cmdfile=/u01/rmanbak/bakl0


把备份脚本放到/u01/rmanbak/script目录下面,vi bakl0,bakl0的内容为:

run{
allocate channel cha1 type disk;
backup
incremental level 0
format '/u01/rmanbak/inc0_%u_%T'(u表示唯一的ID,大T是日期，小t是时间)
tag monday_inc0 //标签可以顺便起，没关系
database;
release channel cha1;
}
，类似就可以写出bakl1,bakl2相应的脚本.


自动备份
crontab
crontab -e -u oracle(改命令的意思是编辑oracle用户的定时执行(-e,edit -u oracle,oracle用户))

分 时 日 月 星期(0代表星期天)
45 23 * * 0 rman target / msglog=bakl0.log cmdfile=bakl0(星期天的23:45会以oracle用户的身份来执行命令)
45 23 * * 1 rman target / msglog=bakl2.log cmdfile=bakl2
45 23 * * 2 rman target / msglog=bakl2.log cmdfile=bakl2
45 23 * * 3 rman target / msglog=bakl1.log cmdfile=bakl1
45 23 * * 4 rman target / msglog=bakl2.log cmdfile=bakl2
45 23 * * 5 rman target / msglog=bakl2.log cmdfile=bakl2
45 23 * * 6 rman target / msglog=bakl2.log cmdfile=bakl2

 

然后启动crontab ,启动crontab的命令:
root> service crond restart

=======================RMAN恢复================

在非catalog模式下，备份的信息存储在controlfile文件中，如果controlfile文件发生毁坏，那么就不能能够进行恢复，
使用在备份的时候需要把controlfile也进行自动备份

RMAN>show all;
using target database control file instead of recovery catalog
RMAN configuration parameters are:
CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
CONFIGURE BACKUP OPTIMIZATION OFF; # default
CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
CONFIGURE CONTROLFILE AUTOBACKUP OFF; # default
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE MAXSETSIZE TO UNLIMITED; # default
CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/home/oracle/product/10.20/dbs/snapcf_ora10g.f'; # default

其中CONFIGURE CONTROLFILE AUTOBACKUP OFF; 没有对controlfile进行 autobackup,使用我们需要运行下面命令来对controlfile进行自动备份
RMAN> CONFIGURE CONTROLFILE AUTOBACKUP ON;

RMAN> show all;

手动备份控制文件：
backup current controlfile


Dbid表示database的一个ID，将来用于恢复spfile和controlfile时候要用到.
RMAN> connect target /
connected to target database: ORA10G (DBID=3988862108)
这个Dbid=3988862108

RMAN> list backup;查看以前备份的信息
RMAN>delete backupset 24;//24代表backupset 的编号
RMAN>backup format '/u01/rmanbak/full_%T_%U.bak' database plus archivelog;(进行一次全备份)

验证备份：
RMAN> validate backupset 3; //3代表backupset的编号

 

口令文件丢失(不属于rman备份的范畴),我们只需要用一个命令来重建这个文件就可以了:
orapw file=orapwsid password=pass entries=5; //口令文件的路径:/u01/oracle/product/10.20/db_1/dbs目录下
oracle> cd /u01/oracle/product/10.20/db_1/dbs
oracle> rm orapwora10g;(文件删除，模拟丢失)
oracle> orapwd file=orapwora10g password=oracle entries=5;(重新建立一个文件),entries的意思(DBA的用户最多有5个)

 

 

SPFILE丢失:
startup nomount;
set dbid 3988862108;
restore spfile from autobackup;
shutdown immediate;
set dbid 3988862108;
startup;

 

模拟操作:
oracle> mv spfileora10g.ora spora10g.ora
oracle>rman target /;
rman> shutdown immediate;
rman> startup nomount;
startup failed: ORA-01078: failure in processing system parameters
LRM-00109: could not open parameter file '/home/oracle/product/10.20/dbs/initora10g.ora'
rman>set dbid 3988862108;
rman>restore spfile from autobackup;

执行该命令，如果没有找到的话，那可能是文件的路径发生错误.可以通过直接赋予它的文件
rman>restore spfile from '/u01/oracle/flash_recovery_area/ORA10G/autobackup/2008_12_09/o1_mf_s_673025706_4mw7xc79_.bkp

在dbs/目录下产生spfileora10g.ora文件。证明spfile 已经恢复好

rman> shutdown immediate;
rman> startup ;(如果该命令不能够启动数据库，那么需要set dbid 3988862108)


controlfile 丢失:
startup nomount;
restore controlfile from autobackup;
alter database mount;
recover database;
alter database open resetlogs;

注意:在做了alter database open resetlogs;会把online redelog file清空，数据文件丢失.所以这个时候要做一个全备份。

oracle>rm *.ctl
oracle>rman target / ;//不能够连接到rman ,因为controlfile丢失
oracle>sqlplus /nolog;


SQL>shutdown immediate; //因为controlfile丢失，不能够正常shutdown
SQL>shutdown abort;

oracle>rman target /;

rman>startup nomount;
rman>restore controlfile from autobackup;
rman>alter database mount;
rman>alter database open resetlogs;

RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of alter db command at 12/09/2008 16:21:13
ORA-01194: file 1 needs more recovery to be consistent
ORA-01110: data file 1: '/home/oracle/oradata/ora10g/system01.dbf

//出错, redo log的scn记录在controlfile里面的，因为我们有新的controlfile,所以需要resetlogs;

/*
resetlogs命令表示一个数据库逻辑生存期的结束和另一个数据库逻辑生存期的开始，每次使用resetlogs命令的时候，SCN不会被重置，不过oracle会重置日志序列号，而且会重置

联机重做日志内容.
这样做是为了防止不完全恢复后日志序列会发生冲突（因为现有日志和数据文件间有了时间差）。
*/
rman>recover database;
rman>alter database open resetlogs;


Redolog file丢失:(下面的这些语句一定要在sqlplus中执行,不是在rman中执行)
(sqlplus/nolog)
1.shutdown immediate;
2.startup mount;
3.recover database until cancel;(media recovery)
4.alter database resetlogs;

 

数据文件丢失(在rman中执行sql语句，在sql后面用双引号括起来):
\1. sql "alter database datafile 3 offline";
\2. restore datafile 3
\3. recover datafile 3
\4. sql "alter database datafile 3 online";

 

表空间丢失:
\1. sql "alter tablespace users offline";//如果文件不存在，则用 sql "alter tablespace users offline immeidate";
\2. restore tablespace users;
\3. recover tablespace users; //与online redolog file 信息一致
\4. sql "alter tablespace users online";

 

非catalog方式完全恢复

数据库出现问题:

1.startup nomount;
2.restore controlfile from autobackup;
3.alter database mount;
4.restore database;
5.recover database;
6.alter database open resetlogs;

 

模拟操作:
oracle ora10g> rm *;
oracle ora10g> ls;
oracle ora10g> //数据文件，控制文件全部删除

oracle ora10g> rman target /; //因为controlfile 丢失，不能够连接到rman
oracle ora10g> sqlplus /nolog;
oracle ora10g> connect / as sysdba;
oracle ora10g> shutdown abort;
oracle ora10g> rman target /

 

rman> startup nomount;
rman> restore controlfile from autabackup;
rman> alter database mount;
rman> restore database;
rman> recover database; //online redolog 不存在

SQL>recover database until cancel; //当redo log丢失，数据库在缺省的方式下，是不容许进行recover操作的,那么如何在这种情况下操作呢
SQL>create pfile from spfile;

vi /u01/product/10.20/dbs/initora10g.ora，在这个文件的最后一行添加
*.allow_resetlogs_corruption='TRUE'; //容许resetlog corruption


SQL>shutdown immediate;
SQL>startup pfile='/u01/product/10.20/dbs/initora10g.ora' mount;
SQL>alter database open resetlogs;

 

基于时间点的恢复:
run{
set until time "to_date(07/01/02 15:00:00','mm/dd/yy hh24:mi:ss')";
restore database;
recover database;
alter database open resetlogs;
}

ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';
1.startup mount;
2.restore database until time "to_date('2009-7-19 13:19:00','YYYY-MM-DD HH24:MI:SS')";
3.recover database until time "to_date('2009-7-19 13:19:00','YYYY-MM-DD HH24:MI:SS')";
4.alter database open resetlogs;

 

如果有open resetlogs,都是不完整恢复.

 

基于 SCN的恢复:
1.startup mount;
2.restore database until scn 10000;
3.recover database until scn 10000;
4.alter database open resetlogs;


基于日志序列的恢复:
1.startup mount;
2.restore database until SEQUENCE 100 thread 1; //100是日志序列
3.recover database until SEQUENCE 100 thread 1;
4.alter database open resetlogs;

日志序列查看命令： SQL>select * from v$log;其中有一个sequence字段.resetlogs就会把sequence 置为1


=================================RMAN catalog模式下的备份与恢复=====================

1.创建Catalog所需要的表空间
SQL>create tablespace rman_ts size datafile '/u01/oracle/oradata/ora10g/rmants.dbf' 20M;

2.创建RMAN用户并授权
SQL>create user rman identified by rman default tablespace rman_ts quota unlimited on rman_ts;
SQL>grant recovery_catalog_owner to rman;(grant connect to rman)


查看角色所拥有的权限: select * from dba_sys_privs where grantee='RECOVERY_CATALOG_OWNER';
(RECOVER_CATALOG_OWNER,CONNECT,RESOURCE)

3.创建恢复目录
oracle>rman catalog rman/rman
RMAN>create catalog tablespace rman_ts;
RMAN>register database;(database是target database)

database registered in recovery catalog
starting full resync of recovery catalog
full resync complete

RMAN> connect target /;

以后要使用备份和恢复，需要连接到两个数据库中,命令:

oracle>rman target / catalog rman/rman (第一斜杠表示target数据库，catalog表示catalog目录 rman/rman表示catalog用户名和密码)

命令执行后显示：

Recovery Manager: Release 10.2.0.1.0 - Production on Wed Dec 10 15:00:42 2008
Copyright (c) 1982, 2005, Oracle. All rights reserved.
connected to target database: ORA10G (DBID=3988862108)
connected to recovery catalog database


命令解释:
Report schema Report shema是指在数据库中需找schema
List backup 从control读取信息
Crosscheck backup 看一下backup的文件，检查controlfile中的目录或文件是否真正在磁盘上
Delete backupset 24 24代表backupset 的编号, 既delete目录，也delete你的文件

 

注意:在做了alter database open resetlogs;会把online redelog file清空，数据文件丢失.所以这个时候要做一个全备份。

resetlogs命令表示一个数据库逻辑生存期的结束和另一个数据库逻辑生存期的开始，每次使用resetlogs命令的时候，SCN不会被重置，不过oracle会重置日志序列号，而且会重置

联机重做日志内容.这样做是为了防止不完全恢复后日志序列会发生冲突（因为现有日志和数据文件间有了时间差）。

 