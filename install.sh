#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Dscription: V2ray ws+tls onekey 
#	Version: 3.3.1
#====================================================

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

nginx_conf_dir="/etc/nginx/conf.d"
nginx_conf="${nginx_conf_dir}/ntt.conf"


source /etc/os-release

#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=`echo ${VERSION} | awk -F "[()]" '{print $2}'`

check_system(){
    
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font} "
        INS="yum"
        echo -e "${OK} ${GreenBG} SElinux 设置中，请耐心等待，不要进行其他操作${Font} "
        setsebool -P httpd_can_network_connect 1
        echo -e "${OK} ${GreenBG} SElinux 设置完成 ${Font} "
        ## Centos 也可以通过添加 epel 仓库来安装，目前不做改动
        cat>/etc/yum.repos.d/nginx.repo<<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF
        echo -e "${OK} ${GreenBG} Nginx 源 安装完成 ${Font}" 
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font} "
        INS="apt"
        ## 添加 Nginx apt源
        if [ ! -f nginx_signing.key ];then
        echo "deb http://nginx.org/packages/mainline/debian/ ${VERSION} nginx" >> /etc/apt/sources.list
        echo "deb-src http://nginx.org/packages/mainline/debian/ ${VERSION} nginx" >> /etc/apt/sources.list
        wget -nc https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
        fi
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${VERSION_CODENAME} ${Font} "
        INS="apt"
        ## 添加 Nginx apt源
        if [ ! -f nginx_signing.key ];then
        echo "deb http://nginx.org/packages/mainline/ubuntu/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list
        echo "deb-src http://nginx.org/packages/mainline/ubuntu/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list
        wget -nc https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
        fi
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font} "
        exit 1
    fi

}
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
dependency_install(){
    ${INS} install wget git lsof -y

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y install crontabs
    else
        ${INS} install cron
    fi
    judge "安装 crontab"

    # 新版的IP判定不需要使用net-tools
    # ${INS} install net-tools -y
    # judge "安装 net-tools"

    ${INS} install bc -y
    judge "安装 bc"

    ${INS} install unzip -y
    judge "安装 unzip"
}
port_alterid_set(){
    stty erase '^H' && read -p "请输入连接端口（default:443）:" port
    [[ -z ${port} ]] && port="443"
}
modify_nginx(){
    ## sed 部分地方 适应新配置修正
    if [[ -f /etc/nginx/nginx.conf.bak ]];then
        cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
    fi
    sed -i "1,/listen/{s/listen 443 ssl;/listen ${port} ssl;/}" ${nginx_conf}
    sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf}
    sed -i "/return/c \\\treturn 301 https://${domain}\$request_uri;" ${nginx_conf}
}
web_camouflage(){
    ##请注意 这里和LNMP脚本的默认路径冲突，千万不要在安装了LNMP的环境下使用本脚本，否则后果自负
    rm -rf /home/wwwroot && mkdir -p /home/wwwroot && cd /home/wwwroot
    git clone https://github.com/Nopoint11/sCalc.git
    judge "web 站点"   
}
nginx_install(){
    ${INS} install nginx -y
    if [[ -d /etc/nginx ]];then
        echo -e "${OK} ${GreenBG} nginx 安装完成 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} nginx 安装失败 ${Font}"
        exit 5
    fi
    if [[ ! -f /etc/nginx/nginx.conf.bak ]];then
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        echo -e "${OK} ${GreenBG} nginx 初始配置备份完成 ${Font}"
        sleep 1
    fi
}
ssl_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install socat nc -y        
    else
        ${INS} install socat netcat -y
    fi
    judge "安装 SSL 证书生成脚本依赖"

    curl  https://get.acme.sh | sh
    judge "安装 SSL 证书生成脚本"

}
domain_check(){
    stty erase '^H' && read -p "请输入你的域名信息(eg:www.abc.com):" domain
    domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    echo -e "${OK} ${GreenBG} 正在获取 公网ip 信息，请耐心等待 ${Font}"
    local_ip=`curl -4 ip.sb`
    echo -e "域名dns解析IP：${domain_ip}"
    echo -e "本机IP: ${local_ip}"
    sleep 2
    if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then
        echo -e "${OK} ${GreenBG} 域名dns解析IP  与 本机IP 匹配 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read install
        case $install in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 继续安装 ${Font}" 
            sleep 2
            ;;
        *)
            echo -e "${RedBG} 安装终止 ${Font}" 
            exit 2
            ;;
        esac
    fi
}

port_exist_check(){
    if [[ 0 -eq `lsof -i:"$1" | wc -l` ]];then
        echo -e "${OK} ${GreenBG} $1 端口未被占用 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 检测到 $1 端口被占用，以下为 $1 端口占用信息 ${Font}"
        lsof -i:"$1"
        echo -e "${OK} ${GreenBG} 5s 后将尝试自动 kill 占用进程 ${Font}"
        sleep 5
        lsof -i:"$1" | awk '{print $2}'| grep -v "PID" | xargs kill -9
        echo -e "${OK} ${GreenBG} kill 完成 ${Font}"
        sleep 1
    fi
}
acme(){
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --force
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} SSL 证书生成成功 ${Font}"
        sleep 2
        ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /etc/v2ray.crt --keypath /etc/v2ray.key --ecc
        if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} 证书配置成功 ${Font}"
        sleep 2
        fi
    else
        echo -e "${Error} ${RedBG} SSL 证书生成失败 ${Font}"
        exit 1
    fi
}
nginx_conf_add(){
    touch ${nginx_conf_dir}/ntt.conf
    cat>${nginx_conf_dir}/ntt.conf<<EOF
    server {
        listen 443 ssl;
        ssl on;
        ssl_certificate       /etc/v2ray.crt;
        ssl_certificate_key   /etc/v2ray.key;
        ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers           HIGH:!aNULL:!MD5;
        server_name           serveraddr.com;
        index index.html index.htm;
        root  /home/wwwroot/sCalc;
        error_page 400 = /400.html;
        
}
    server {
        listen 80;
        server_name serveraddr.com;
        return 301 https://www.abc.com\$request_uri;
    }
EOF

modify_nginx
judge "Nginx 配置修改"

}

start_process_systemd(){
    ### nginx服务在安装完成后会自动启动。需要通过restart或reload重新加载配置
    systemctl start nginx 
    judge "Nginx 启动"

    systemctl enable nginx
    judge "设置 Nginx 开机自启"

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

main(){
    is_root
    check_system
    time_modify
    dependency_install
    domain_check
    port_exist_check 80
    port_exist_check ${port}
    nginx_install
    nginx_conf_add

    #改变证书安装位置，防止端口冲突关闭相关应用
    systemctl stop nginx
    systemctl stop v2ray
    
    #将证书生成放在最后，尽量避免多次尝试脚本从而造成的多次证书申请
    ssl_install
    acme
    
    start_process_systemd
    acme_cron_update
}

main
