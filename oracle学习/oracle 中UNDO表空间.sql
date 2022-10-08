--²Î¿¼ https://wenku.baidu.com/view/0f95c60d677d27284b73f242336c1eb91a373315.html

select file_id,file_name,tablespace_name,sum(bytes)/1024/1024 total_mb,autoextensible from dba_data_files group by file_name,file_id,tablespace_name,autoextensible order by file_id;


select addr,used_ublk  from v$transaction;

select begin_time,end_time,undoblks from v$undostat  order by begin_time desc ;

select max(undoblks/(end_time-begin_time)*24*3600) from v$undostat;

select (sum(undoblks))/sum((end_time-begin_time)*86400) from v$undostat;

show parameter db_block_size;

show parameter  pfile ;
select (UR*(UPS*DBS))+(DBS*24) as "bytes" from (select value as UR from v$parameter where name='undo_retention'),
(select (sum(undoblks)/sum(((end_time-begin_time)*86400))) as ups from v$undostat),(select value as DBS from v$parameter where name='db_block_size');


create pfile='/home/oracle/pfile.new' from spfile='/u01/app/oracle/product/11.2.0/db_1/dbs/spfilewingdb.ora';