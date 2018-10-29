# Multi Instance Redis Discovery Template for Zabbix 3.4
------
*Zabbix server must be >= 3.4*
*Need command: redis-cli, ss and telnet*

> * Discovering redis instances and who is slave through ports
> * Get redis info/config/slaveinfo and output json format
> * Create "Dependent Item" by "preprocessing"
> * Generate graphs and Key indicators trigger

![Alt text](https://github.com/cuimingkun/zbx_tem_redis/blob/master/graphs.png)

# UPDATE 2018-10-29
-----
For a better maintainability a bash script is implemented.

## Installation
*Needed commands: redis-cli, ss*

Put the ***userparameter_redis_lld_plus.conf*** into ***</your/userparameter/path/>*** directory.    
To start using it, just install the script ***zbx_rds.sh*** in ***/usr/local/bin*** dir and give execution permissions via
`chmod +x /usr/local/bin/zbx_rds.sh`

### Configuration
There are 2 variables that you can customize baserd on your installation and are at the beginning of the script:
```
REDIS_CONF=/etc/redis.conf
REDIS_HOST=127.0.0.1
```
***Please, change it accordingly to your installation***

Import the template ***redis_templates_for_zbx_3.4.xml*** in Zabbix.


## Legacy instalation
On the zabbix server web page import XML template file ***redis_templates_for_zbx_3.4_legacy.xml***.

If no authentication is in place, please remove the following from the ***</your/userparameter/path/>userparameter_redis_lld_plus.conf***:
`(echo AUTH $(sudo /bin/grep requirepass /etc/redis.conf | sed 's/requirepass//g' | sed 's/\s*//g' | sed 's/"//g');`
