#!/usr/bin/env bash

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
stty erase ^?

install_packages() {
	rpm_packages="tar zip unzip openssl openssl-devel lsof git jq socat crontabs make gcc rrdtool rrdtool-perl perl-core spawn-fcgi traceroute zlib zlib-devel wqy-zenhei-fonts nc"
	apt_packages="tar zip unzip openssl libssl-dev lsof git jq socat cron make gcc rrdtool librrds-perl spawn-fcgi traceroute zlib1g zlib1g-dev fonts-droid-fallback netcat"
	if [[ $ID == "debian" || $ID == "ubuntu" ]]; then
		$PM update
		$INS wget curl gnupg2 ca-certificates dmidecode lsb-release
		update-ca-certificates
		$PM update
		$INS $apt_packages
	elif [[ $ID == "centos" ]]; then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
		setenforce 0
		$INS wget curl ca-certificates dmidecode epel-release
		update-ca-trust force-enable
		$INS $rpm_packages
    elif [[ $ID == "amzn" ]]; then 
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
		setenforce 0
		$INS wget curl ca-certificates dmidecode
		update-ca-trust force-enable
		amazon-linux-extras install epel -y
		$INS https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
		$INS $rpm_packages
    elif [[ $ID == "ol" ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
		setenforce 0
        cat > /etc/yum.repos.d/elrepo.repo <<EOF
[ol_developer_EPEL]
name=Oracle Linux Developement Packages
baseurl=http://yum.oracle.com/repo/OracleLinux/OL$releasever/developer_EPEL/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF
		$INS wget curl ca-certificates dmidecode
		update-ca-trust force-enable
		$INS $rpm_packages
    fi
}

get_info() {
	source /etc/os-release || source /usr/lib/os-release || exit 1
	if [[ $ID == "centos"  || $ID == "amzn"  || $ID == "ol" ]]; then
		PM="yum"
		INS="yum install -y"
		releasever=${VERSION: 0: 1}
	elif [[ $ID == "debian" || $ID == "ubuntu" ]]; then
		PM="apt-get"
		INS="apt-get install -y"
	else
		exit 1
	fi
	read -rp "输入服务器名称（如 香港）:" name
	read -rp "输入服务器代号（如 HK）:" code
	read -rp "输入通信密钥（不限长度）:" sec
	read -rp "输入 Nginx 站点配置目录:" nginx_conf_dir
	read -rp "输入 Nginx fastcgi_params 目录:" nginx_fastcgi
	read -rp "输入域名:" domain
	read -rp "输入内部输出端口（默认 9006）：" port1
	[ -z "$port1" ] && port1="9006"
	testport=$port1 && port_test
	read -rp "输入 FCGI 监听端口（默认 9007）：" port2
	[ -z "$port2" ] && port2="9007"
	testport=$port1 && port_test
}

port_test() {
  	if [[ $testport -le 0 ]] || [[ $testport -gt 65535 ]]; then
    		print_error "请输入 0-65535 之间的值"
    		exit 1
  	fi
  	ss -tnlp | grep -q ":${testport} " && echo "端口 ${testport} 已被占用" && exit 1
}

compile_smokeping() {
	[[ -e /usr/local/smokeping ]] && rm -rf /usr/local/smokeping
	[[ -e /tmp/smokeping ]] && rm -rf /tmp/smokeping
	mkdir -p /tmp/smokeping
	cd /tmp/smokeping
	wget https://github.com/oetiker/SmokePing/releases/download/2.7.3/smokeping-2.7.3.tar.gz
	tar xzvf smokeping-2.7.3.tar.gz
	cd smokeping-2.7.3
	./configure --prefix=/usr/local/smokeping
	if type -P make && ! type -P gmake; then
		ln -s $(type -P make) /usr/bin/gmake
	fi
	make install || gmake install
	[[ ! -e /usr/local/smokeping/bin/smokeping ]] && echo "编译 SmokePing 失败" && exit 1
}

configure() {
	origin="https://github.com/KukiSa/smokeping-lnmp/raw/main"
	ip=$(curl -sL https://api64.ipify.org -4) || error=1
	[[ $error -eq 1 ]] && echo "获取本机 IP 地址失败" && exit 1
	wget $origin/tcpping-sp -O /usr/bin/tcpping-sp && chmod +x /usr/bin/tcpping-sp
	cat > $nginx_conf_dir/$domain.conf <<EOF
server {
	listen 80;
	listen [::]:80;
	listen 127.0.0.1:$port1;
	server_name $domain;
	index index.html index.htm smokeping.fcgi;
	root /usr/local/smokeping/htdocs/;
	#error_page 404/404.html;
	
	location ~ .*\.fcgi\$ {
		fastcgi_pass 127.0.0.1:$port2;
		include $nginx_fastcgi/fastcgi_params;
	}

	access_log /dev/null;
	error_log /dev/null;
}
EOF
	nginx -s reload
	wget $origin/config -O /usr/local/smokeping/etc/config
	wget $origin/systemd-fcgi -O /etc/systemd/system/spawn-fcgi.service
	wget $origin/systemd-master -O /etc/systemd/system/smokeping-master.service
	wget $origin/systemd-slave -O /etc/systemd/system/smokeping-slave.service
	sed -i 's/port1/'${port1}'/g;s/port2/'${port2}'/g' /etc/systemd/system/smokeping-slave.service /etc/systemd/system/spawn-fcgi.service
	sed -i 's/some.url/'$domain'/g' /usr/local/smokeping/etc/config
	sed -i 's/SLAVE_CODE/'$code'/g' /usr/local/smokeping/etc/config /etc/systemd/system/smokeping-slave.service
	sed -i 's/SLAVE_NAME/'$name'/g' /usr/local/smokeping/etc/config
	systemctl daemon-reload
	systemctl enable spawn-fcgi smokeping-master smokeping-slave
	echo "$code:$sec" > /usr/local/smokeping/etc/smokeping_secrets.dist
	echo "$sec" > /usr/local/smokeping/etc/secrets
	chmod 700 /usr/local/smokeping/etc/secrets /usr/local/smokeping/etc/smokeping_secrets.dist
	chown www:www /usr/local/smokeping/etc/smokeping_secrets.dist
	cd /usr/local/smokeping/htdocs
	mkdir -p data var cache ../cache
	mv smokeping.fcgi.dist smokeping.fcgi
	../bin/smokeping --debug || error=1
	[[ $error -eq 1 ]] && echo "测试运行失败！" && exit 1
}


get_info
install_packages
compile_smokeping
configure

systemctl start spawn-fcgi smokeping-master smokeping-slave || error=1
[[ $error -eq 1 ]] && echo "启动失败" && exit 1

rm -rf /tmp/smokeping

echo "安装完成，页面网址：http://$domain （监控数据不会立即生成）"
