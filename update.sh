#!/usr/bin/env bash

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
stty erase ^?

get_info() {
	read -rp "请输入服务器名称（如 香港）:" name
	tail -n 3 /usr/local/smokeping/etc/config
	read -rp "请输入 slaves = 的字符:" code
	port1=9006
	port2=9007
}

configure() {
	origin="https://github.com/KukiSa/smokeping-lnmp/raw/main"
	wget $origin/tcpping-sp -O /usr/bin/tcpping-sp && chmod +x /usr/bin/tcpping-sp

	nginx -s reload
	wget $origin/config -O /usr/local/smokeping/etc/config
	wget $origin/systemd-fcgi -O /etc/systemd/system/spawn-fcgi.service
	wget $origin/systemd-master -O /etc/systemd/system/smokeping-master.service
	wget $origin/systemd-slave -O /etc/systemd/system/smokeping-slave.service
	sed -i 's/port1/'${port1}'/g;s/port2/'${port2}'/g' /etc/systemd/system/smokeping-slave.service /etc/systemd/system/spawn-fcgi.service
	sed -i 's/SLAVE_CODE/'$code'/g' /usr/local/smokeping/etc/config /etc/systemd/system/smokeping-slave.service
	sed -i 's/SLAVE_NAME/'$name'/g' /usr/local/smokeping/etc/config
	systemctl disable smokeping
	rm -rf /etc/systemd/system/smokeping.service
	systemctl daemon-reload
	systemctl enable caddy-sp spawn-fcgi smokeping-master smokeping-slave
	rm -rf /usr/local/smokeping/htdocs/cache/*
	rm -rf /usr/local/smokeping/htdocs/data/*
}

get_info
configure

systemctl start spawn-fcgi smokeping-master smokeping-slave || error=1
[[ $error -eq 1 ]] && echo "启动失败" && exit 1

echo "升级完成（监控数据不会立即生成）"
