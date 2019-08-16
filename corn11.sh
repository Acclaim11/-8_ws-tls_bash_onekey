#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: V2ray ws+tls onekey 
#	Version: 3.3.1
#	Blog: https://www.wulabing.com
#	Official document: www.v2ray.com
#====================================================

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

v2ray_conf_dir="/etc/v2ray"
nginx_conf_dir="/etc/nginx/conf.d"
v2ray_conf="${v2ray_conf_dir}/config.json"
nginx_conf="${nginx_conf_dir}/v2ray.conf"

#生成伪装路径
camouflage=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`

source /etc/os-release

#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=`echo ${VERSION} | awk -F "[()]" '{print $2}'`

is_root(){
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font} "
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}" 
        exit 1
    fi
}
judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}
ntpdate_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install ntpdate -y
    else
        ${INS} update
        ${INS} install ntpdate -y
    fi
    judge "安装 NTPdate 时间同步服务 "
}
time_modify(){

    ntpdate_install

    systemctl stop ntp &>/dev/null

    echo -e "${Info} ${GreenBG} 正在进行时间同步 ${Font}"
    ntpdate time.nist.gov

    if [[ $? -eq 0 ]];then 
        echo -e "${OK} ${GreenBG} 时间同步成功 ${Font}"
        echo -e "${OK} ${GreenBG} 当前系统时间 `date -R`（请注意时区间时间换算，换算后时间误差应为三分钟以内）${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 时间同步失败，请检查ntpdate服务是否正常工作 ${Font}"
    fi 
}
start_process_systemd(){
    ### nginx服务在安装完成后会自动启动。需要通过restart或reload重新加载配置
    systemctl start nginx 
    judge "Nginx 启动"


    systemctl start v2ray
    judge "V2ray 启动"
}

acme_cron_update(){
    if [[ "${ID}" == "centos" ]];then
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
        > /dev/null && systemctl start nginx " /var/spool/cron/root
    else
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
        > /dev/null && systemctl start nginx " /var/spool/cron/crontabs/root
    fi
    judge "cron 计划任务更新"
}
