# 自动化运维Ansible之安装部署

参考地址：https://www.cnblogs.com/jasonminghao/p/12635384.html

目录

- [1、SSH分发](https://www.cnblogs.com/jasonminghao/p/12635384.html#1ssh分发)
- [2、安装Ansible](https://www.cnblogs.com/jasonminghao/p/12635384.html#2安装ansible)
- [3、Ansible清单管理](https://www.cnblogs.com/jasonminghao/p/12635384.html#3ansible清单管理)



# 1、SSH分发

> ansible自动化部署条件
> 1.建议基于ssh密钥方式建立远程连接
> 2.基于ssh口令方式建立远程连接（不建议）

在部署之前需要保证`管理主机`和`受控主机`能够基于`ssh密钥`的方式进行`远程连接`

`管理主机`生成SSH密钥（私钥和公钥），分发公钥到每台`受控主机`：

1.安装sshpass

```bash
[root@m01 ~]# yum install sshpass -y
```

2.生成密钥

```bash
//  直接生成密钥
[root@m01 ~]# ssh-keygen -t dsa -f /root/.ssh/id_dsa -N ""
Generating public/private dsa key pair.
Created directory '/root/.ssh'.
Your identification has been saved in /root/.ssh/id_dsa.
Your public key has been saved in /root/.ssh/id_dsa.pub.
The key fingerprint is:
SHA256:gfr8/bG2IAzxNJiom7WGwba8G26BZ5yfxJMp6O3Ouh4 root@m01
The key's randomart image is:
+---[DSA 1024]----+
|                 |
|     . +         |
|    . = +        |
| . . . + o       |
| +=ooo. S        |
|ooBB*+ o         |
|.EO=ooo o . .    |
| o+=o  . o ..o   |
|.=O=    . .o+.   |
+----[SHA256]-----+
```

3.分发密钥

```bash
//  免交互式批量分发公钥脚本
[root@m01 ~]# vim ~/ssh-fenfa.sh
#!/bin/bash
rm -f /root/.ssh/id_dsa 
ssh-keygen -t dsa -f /root/.ssh/id_dsa -N ""
  for ip in 67 68  
do
sshpass -p jpj168 ssh-copy-id -i /root/.ssh/id_dsa.pub "-o StrictHostKeyChecking=no" 192.168.6.$ip
done

// 执行脚本
[root@m01 ~]# sh ~/ssh-fenfa.sh
```

4.一键ssh登录测试for循环

```bash
[root@m01 ~]# for i in 67 68 ;do ssh 192.168.6.$i  date ;done
2022年 03月 27日 星期日 22:55:21 CST
2022年 03月 27日 星期日 22:55:21 CST
```

# 2、安装Ansible

> 安装方法有很多，这里仅仅以Centos7 yum安装为例。

Ansible软件默认不在标准仓库中，需要用到repo源。

1.需在管理机器上安装：

```bash
// 添加repo
[root@m01 ~]# yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

// yum安装ansilbe
[root@m01 ~]# yum install ansible -y
[root@m01 ~]# rpm -qa ansible

// 检查ansible版本
[root@m01 ~]# ansible --version
ansible 2.9.27
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/root/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.5 (default, Oct 30 2018, 23:45:53) [GCC 4.8.5 20150623 (Red Hat 4.8.5-36)]
```

2.添加主机清单

```bash
[root@m01 ~]# vim /etc/ansible/hosts
[ans]
192.168.6.67
192.168.6.68
```

> [sa] 分组下添加了两个hosts

3、测试ansible

> ping模块用于测试ansible与被受控端的连通性

```bash
[root@centos ~]# ansible ans -m ping
192.168.6.67 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
192.168.6.68 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"

```

