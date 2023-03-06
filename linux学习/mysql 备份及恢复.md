# mysql 备份及恢复





[TOC]





###  mysqldump 备份恢复

##### 备份语句

```sh
 #备份整个数据库
 mysqldump -u root -p123456 -B -F --master-data=2 --single-transaction --triggers --routines --events  test > /database/test_bak.sql
 #压缩
 mysqldump -u root -p123456 -B -F --master-data=2 --single-transaction --triggers --routines --events test |gzip> /database/test_bak.sql.gz
#备份整个books表
mysqldump -uroot -p123456 test books > /database/test_book_bak.sql
```

##### 恢复语句

```sh
#恢复整个数据库 备份有-B参数
mysql -uroot -p123456 < test_bak.sql
#恢复整个数据库 备份没有-B参数
mysql -uroot -p123456 test < test_bak.sql
#压缩恢复整个数据库备份没有-B参数
gunzip < test_bak.sql.gz | mysql -uroot -p123456 test
#恢复整个books表
mysql -uroot -p123456 test <test_book_bak.sql
```



##### mysql-bin日志查看

```sh
mysqlbinlog -d test /data/mysql/mysql-bin.000011
```

##### mysql-bin日志恢复

```sh
mysqlbinlog -d test  /data/mysql/mysql-bin.000011 | /database/mysql/bin/mysql -uroot -p123456 test
```



##### mysql-bin日志位置点恢复

```sh
mysqlbinlog -d test --start-position=123 --stop-position=154 /data/mysql/mysql-bin.000011 | /database/mysql/bin/mysql -uroot -p123456 test
```



##### 查看错误日志

```sql
mysql> show variables like '%log_error%';
```

##### 查看二进制日志

```sql
show variables like '%log_bin%';
```



### Linux 设置 MySQL 每天定时备份脚本

##### vim mysql_backup.sh

```sh
#!/bin/bash
#定义变量信息
mysql_user="root"
mysql_password="123456"
mysql_host="localhost"
mysql_port="3306"
mysql_database="test"
backup_dir="/database/mysqlbackup"
backup_date=$(date +%Y%m%d)
 
echo "备份开始......"
 
# 备份数据库
/database/mysql/bin/mysqldump -B -F --master-data=2 --single-transaction --triggers --routines --events  -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password $mysql_database |gzip> $backup_dir/mysql_backup_$backup_date.sql.gz
 
echo "备份结束!"
```

##### 设置脚本可执行权限

```sh
chmod 777 mysql_backup.sh
```



### 设置定时任务，每天定时执行

##### 编辑定时任务配置文件

```sh
vim /etc/crontab
```


新增在配置文件，最后一行，此处设置的是每天1点执行一次

```
0 01 * * * root /database/mysqlbackup/mysql_backup.sh
```

格式定义如下图：

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212180609133.png" alt="image-20230212180609133" style="zoom:80%;" />

| 字段 | 描述             | 允许的值             |
| :--- | ---------------- | -------------------- |
| 分钟 | 一小时的第几分   | 0-59                 |
| 小时 | 一天的第几小时   | 0-23                 |
| 日期 | 一个月的的第几天 | 1-31                 |
| 月份 | 一年的第几个月   | 1-12                 |
| 周几 | 一周的第几天     | 0-6                  |
| 命令 | 命令             | 可以被执行的任何命令 |



常用格式：

```sh
crontab每分钟定时执行：

*/1 * * * * root /mysql_backup.sh //每隔1分钟执行一次
*/10 * * * * root /mysql_backup.sh //每隔10分钟执行一次

crontab每小时定时执行：

0 */1 * * * root /mysql_backup.sh //每1小时执行一次
0 */2 * * * root /mysql_backup.sh //每2小时执行一次

crontab每天定时执行：

0 10 * * * root /mysql_backup.sh //每天10点执行
30 19 * * * root /mysql_backup.sh //每天19点30分执行

crontab每周定时执行：

0 10 * * 1 root /mysql_backup.sh //每周一10点执行
30 17 * * 5 root /mysql_backup.sh //每周五17点30分执行

crontab每年定时执行：

0 10 1 10 * root /mysql_backup.sh //每年的10月1日10点执行
0 20 8 8 * root /mysql_backup.sh //每年的8月8日20点执行

```

##### 重新加载，立即生效

```sh
crontab /etc/crontab
```

##### 查看定时任务

```
crontab -l
```







### navicat 转储备份

![image-20230212171342484](C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212171342484.png)

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212172207441.png" alt="image-20230212172207441" style="zoom: 80%;" />



### navicat 转储恢复

##### 需要手工创建数据库

```sql
CREATE DATABASE test;
```

![image-20230212172850433](C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212172850433.png)

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212172931081.png" alt="image-20230212172931081" style="zoom:80%;" />

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212173026849.png" alt="image-20230212173026849" style="zoom:80%;" />







### navicat nb3备份

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212173540400.png" alt="image-20230212173540400" style="zoom:67%;" />

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212174351002.png" alt="image-20230212174351002" style="zoom:67%;" />

### navicat nb3还原

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212174612517.png" alt="image-20230212174612517" style="zoom:80%;" />

<img src="C:%5CUsers%5CAdministrator%5CAppData%5CRoaming%5CTypora%5Ctypora-user-images%5Cimage-20230212174842421.png" alt="image-20230212174842421" style="zoom:67%;" />



