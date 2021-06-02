# 常见问题
## 安装过程
### `epel/x86_64` 错误
常见于 Amazon Linux 2 (AMI)，因 AWS 与 fedoraproject.org 之间随机存在连通性问题，而 Amazon Linux 2 官方指导[\[1\]](https://aws.amazon.com/cn/premiumsupport/knowledge-center/ec2-enable-epel)[\[2\]](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/add-repositories.html)中指示使用 `amazon-linux-extras install epel -y` 命令或 `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` 命令安装的 ELRepo 源均以 fedoraproject.org 为 Baseurl 或 Metalink 终结点。

**解决方案：** 更换非 Amazon Linux 2 系统。

### `Unit smokeping.services not found`
SmokePing 的 systemd 文件未被写入 `/usr/lib/systemd/system`。

**解决方案：** 执行 `wget https://raw.githubusercontent.com/KukiSa/smokeping/main/systemd -O /etc/systemd/system/smokeping.service && systemctl daemon-reload && systemctl enable smokeping`。

### `Net-SSLeay` 编译失败
常见于 Amazon Lightsail 的 Debian 机器上，初步判断为 Debian 模板因 SWAP 分区默认未分配导致编译器运行异常。

**解决方案：** 增加 SWAP。

## 使用过程
### 报错：`we did not get the config from the master`
Slave 模式下的 SmokePing 与 Master 模式下的 SmokePing 通信失败，一般为防火墙阻止。

**解决方案：** 本机防火墙放行 9006 端口。

### 一直没有记录数据
请等待至少 30 分钟，若仍旧无数据，请执行 `systemctl status smokeping`。若发现输出有前述报错，请照前款解决方案。

### 配置 SSL 后网站显示“您的连接并非完全安全”
SmokePing 前端将会引用 SmokePing 配置文件中的 `cgiurl`，此项默认为 HTTP。

**解决方案：** 修改 `/usr/local/smokeping/etc/config` 第 10 行 `cgiurl   = http://`，将 `http://` 改为 `https://`。

## 定制主从分离
### 将本机作为从端，将主端改至其他机器上
修改 `/usr/local/smokeping/bin/slave.sh` 第 8 行的 `--master-url=http://127.0.0.1:9006/smokeping.fcgi` 为主端的 URL，执行 `systemctl restart smokeping` 以应用。

### 将本机作为主端，接收其他从端机器发送的结果
修改 `/etc/nginx/conf.d/smokeping.conf` 第 2 行的 `listen 127.0.0.1:9006;` 为 `listen 9006;`，第 3 行的 `listen [::1]:9006;` 为 `listen [::]:9006;`，执行 `systemctl restart nginx` 以应用。
