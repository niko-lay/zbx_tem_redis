#! /bin/sh
#
# zbx_rds_stats.sh
# Copyright (C) 2018 Stefano Stella <mprenditore@gmail.com>
#
# Distributed under terms of the MIT license.
#
# The following is a shell script adaptation from the oneliners
#      userparameters of this repo: https://github.com/cuimingkun/zbx_tem_redis
#
# Required software:
#      - redis-cli
#      - ss

# ENV
VERSION="1.0"
REDIS_CONF=/etc/redis.conf
REDIS_HOST=127.0.0.1
# if you have a single redis instance, you can use Redis SOCKET to speed up the connection
# REDIS_SOCK=/var/run/redis/redis.sock  # comment out to use REDIS_HOST:REDIS_PORT instead of socket

# ARGS
KEY_TYPE=$1
REDIS_PORT=$2
# FILTER_OUT=$3
ARG_COUNT=$#
ARGS=$@

# TMP_VARS
# comment REDIS_PASS if you do not have authentication in place or 
REDIS_PASS=$(/bin/grep requirepass ${REDIS_CONF} | sed 's/requirepass//g' | sed 's/\s*//g' | sed 's/"//g')

function usage(){
    echo "Welcome to Zabbix Redis statistics v.$VERSION"
    echo -e "\nUSAGE: $0 COMMAND [redis_port] [regexp]"
    echo -e "\nExamples:\n"
    echo "$0 discovery"
    echo "$0 repl_discovery"
    echo "$0 ping 6379"
    echo "$0 info_json 6379 redis_version"
    echo "$0 config_json 6379 maxmemory"
    echo "$0 slaveinfo_json 6379 master_host"
}

function check_args(){
    if [ "$ARG_COUNT" -ne "$1" ]; then
        echo "[DEBUG] args: $ARGS" >&2
        echo "[ERROR] Not enough parameters for the command." >&2
        echo -e "Please check the usage documentation.\n" >&2
        usage >&2
        false
    else
        true
    fi
}

function SS_CMD(){
    /sbin/ss -4lp | grep redis-server | awk -F':' '{print $2}'| awk '{print $1}' | awk NF 
}

function REDIS_CMD(){
    if [ ! -z "$REDIS_PASS" ]; then
        AUTH_OPT="-a ${REDIS_PASS}"
    fi
    if [ ! -z "$REDIS_SOCK" ] && [ -e "$REDIS_SOCK" ]; then
        (echo "$1"; sleep 0.1) | redis-cli ${AUTH_OPT} -s ${REDIS_SOCK} 2>/dev/null
    else
        (echo "$1"; sleep 0.1) | redis-cli ${AUTH_OPT} -h ${REDIS_HOST} -p ${REDIS_PORT} 2>/dev/null
    fi
}

function REDIS_CLI(){
    REDIS_CMD "$1" | grep -v "^#" | while read line; do echo $line | tr -d '[:space:]'; echo ; done
}

function info_json(){
    echo "$2" | sed -e s/:ok$/:yes/g | awk NF |
        sed -e s/^/'"'/g -e s/'$'/'",'/g -e s/':'/'":"'/g | tr -d \\n |
        sed -e s/^/\{\"$1\"\:\{/g -e s/',$'/}}/g | tr -d \\n
}

function config_to_json(){
    echo "$1" | sed '/^requirepass/,+1 d' | sed '/^masterauth/,+1 d' |
        sed -e 's/^/"&/g' -e 's/$/&"/g' | sed 'N;s/\n/:/g' | sed -e s/'$'/','/g | tr -d \\n |
        sed -e s/^/'{"redis_config":{'/g -e s/',$'/}}/g
}

function exec_action(){
    case "${KEY_TYPE}" in
        discovery)  SS_CMD| sed -e s/^/'{"{\#REDIS_PORT}": "'/g -e s/'$'/'"},'/g | tr -d \\n |
                            sed -e s/^/'{"data":['/g -e s/',$'/]}/g ;;
        ping)  REDIS_CLI "ping" | grep 'PONG' | wc -l ;;
        info_json)  info_json redis_info "$(REDIS_CLI "info")" ;;
        config_json) config_to_json "$(REDIS_CLI "config get *")" ;;
        repl_discovery) SS_CMD | while read line; do
                                    REDIS_PORT=$line
                                    role=$(REDIS_CLI "info" | grep 'role:slave' | awk -F':' '{print $2}')
                                    if [ "$role" == "slave" ]; then
                                        echo "SLAVE:$REDIS_PORT" | sed -e s/^/'{"{\#REDIS_PORT_'/g |
                                            sed -e s/'$'/'"},'/g -e s/':'/'}": "'/g
                                    fi
                                done| tr -d \\n | sed -e s/^/'{"data":['/g -e s/',$'/]}/g ;;
        slaveinfo_json) info_json redis_slaveinfo "$(REDIS_CLI "info Replication")" ;;
    esac
}

# MAIN
RESULT=$(exec_action)
if [ -z "$RESULT" ]; then
    echo "ZBX_UNSUPPORTED"
    exit -1
fi
    echo $RESULT
    exit 0
