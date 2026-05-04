# docker-phantun
这是一个一键运行 phantun 的 docker 镜像：

对于会用docker的人来说，它能减少运行Phantun需要的手动操作，大幅降低脑细胞死亡数量。


下面以一个转发Sing-box发布的HY2协议的场景为例，演示此镜像的用法。
拓扑： 家庭PC <=> 家里运行Docker版Phantun客户端的x86虚拟机 <====互联网====> VPS上Docker中的Phantun服务端 <=> VPS上的Sing-box HY2协议端口
VPS上的Sing-box发布的HY2协议UDP端口号：10000
VPS上的Phantun服务端监听的TCP端口号：20000
家里虚拟机Phantun客户端监听的UDP端口号：10000

一、基础准备
家里虚拟机和VPS上都要开启内核IPv4转发
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
VPS端的防火墙开启TCP 20000 端口的入站放行。

二、VPS上的服务端部署Phantun服务端
1.安装Docker-CE
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh
2. 创建Phantun服务端的Docker Compose配置文件，内容如下：
services:
  phantun-server:
    image: metrak/phantun:latest
    container_name: phantun-server
    network_mode: "host"
    cap_add: [NET_ADMIN]
    devices: [/dev/net/tun]
    environment:
      - NIC=ens18        # 用ip add或ifconfig查一下网卡的真实名称
      - TCP_PORT=20000   # Phantun 监听的公网伪装 TCP 端口
    command: ["server", "--local", "20000", "--remote", "127.0.0.1:10000"]
    restart: unless-stopped
保存退出后：
docker compose up -d

三、家里虚拟机部署Phantun客户端
1.安装Docker-CE
国内网络安装方法参见清华大学镜像源的相关说明：
https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/
连不上dockerhub可使用代理或在docker服务的配置文件"/etc/systemd/system/multi-user.target.wants/docker.service"中配置代理解决。
2.创建Phantun客户端的Docker Compose配置文件，内容如下：
services:
  phantun-client:
    image: metrak/phantun:latest
    container_name: phantun-client
    network_mode: "host"
    cap_add: [NET_ADMIN]
    devices: [/dev/net/tun]
    environment:
      - NIC=ens18        # 用ip add或ifconfig查一下网卡的真实名称
      - TCP_PORT=20000
    command: ["client", "--local", "127.0.0.1:10000", "--remote", "你的VPS公网IP:20000"]
    restart: unless-stopped
保存退出后：
docker compose up -d

四、家庭PC测试
客户端软件如V2RayN等，将原本直接连VPS上HY2的配置文件，目标IP地址改为家里虚拟机的内网IP，端口号不变。

测试效果。
