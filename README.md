# SmokePing 一键脚本 for 宝塔/LNMP

[SmokePing](https://oss.oetiker.ch/smokeping) 是由 [RRDtool](https://oss.oetiker.ch/rrdtool) 的作者 [Tobi Oetiker](https://www.oetiker.ch) 开发的一款监控网络状态和稳定性的开源软件。SmokePing 会不断向目标发送各种类型的数据包，并对返回值进行测量和记录，通过 RRDtool 制图程序图形化地展示在各个时段内网络的延迟和丢包情况，帮助我们更清楚、更直观地了解监控机和监控目标之间短期和长期的网络状况。

本项目旨在使 SmokePing 运行在 [Nginx](https://nginx.org) 上而非大部分教程指导的运行在 [Apache 2](https://httpd.apache.org) 上并在已经安装 Web 服务的系统上对原有环境无损的情况下快速地部署 SmokePing 进行监控。

初步支持[宝塔](https://bt.cn)和 [LNMP.org](https://lnmp.org) 一键包安装的以 Nginx 为最前端的环境。 

系统上，目前支持 [Amazon Linux 2 (AMI)](https://aws.amazon.com/amazon-linux-2), [CentOS 7](https://www.centos.org) 及以上、[Debian 9](https://www.debian.org) 及以上、[Oracle Linux 7](https://www.oracle.com/linux) 及以上和 [Ubuntu 18](https://ubuntu.com) 及以上的 Linux 发行版。

本项目的上游为 [jiuqi9997/smokeping](https://github.com/jiuqi9997/smokeping)，感谢 97 提供的思路和主要代码。

## 安装
### 宝塔面板
1. 进入宝塔面板，添加一个站点。填写域名时务必将第一行的域名记住。不要急于修改网站配置文件和添加 SSL。
2. 执行 `bash -c "$(curl -L https://github.com/KukiSa/smokeping-lnmp/raw/main/install.sh)"`，根据提示操作。
3. 脚本执行完成后，可以进入宝塔面板对站点进行添加 SSL 证书等操作。

### LNMP.org 一键包
1. 执行 `lnmp vhost add` 以添加一个站点，暂时不要配置 SSL。
2. 执行 `bash -c "$(curl -L https://github.com/KukiSa/smokeping-lnmp/raw/main/install.sh)"`，根据提示操作。
3. 脚本执行完成后，可以按需修改网站的配置文件。

## 常见问题
### `epel/x86_64` 错误
常见于 Amazon Linux 2 (AMI)，因 AWS 与 fedoraproject.org 之间随机存在连通性问题，而 Amazon Linux 2 官方指导[\[1\]](https://aws.amazon.com/cn/premiumsupport/knowledge-center/ec2-enable-epel)[\[2\]](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/add-repositories.html)中指示使用 `amazon-linux-extras install epel -y` 命令或 `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` 命令安装的 ELRepo 源均以 fedoraproject.org 为 Baseurl 或 Metalink 终结点。

**解决方案：** 更换非 Amazon Linux 2 系统。

### 中文显示异常
常见于 Debian 或 Ubuntu，可能因系统精简掉了中文字体。

**解决方案：** 执行 `apt-get install -y wqy-zenhei-fonts`。


## SmokePing 配置
SmokePing 主配置文件（包括目标节点）为 `/usr/local/smokeping/etc/config`，此文件的结构及其修改请查阅相关教程，附上[官方 Examples](https://oss.oetiker.ch/smokeping/doc/smokeping_examples.en.html)。
