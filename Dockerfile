FROM alpine:latest

# 安装必要的网络工具包和下载工具
RUN apk add --no-cache bash iptables iproute2 wget unzip

# 使用 ARG 接收外部传入的版本号，默认值为 v0.8.1
ARG PHANTUN_VER=v0.8.1
ENV ARCH=x86_64-unknown-linux-musl

# 下载、解压官方 Release
RUN wget https://github.com/dndx/phantun/releases/download/${PHANTUN_VER}/phantun_${ARCH}.zip -O /tmp/phantun.zip && \
    unzip /tmp/phantun.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/phantun_server /usr/local/bin/phantun_client && \
    rm /tmp/phantun.zip

# 拷贝并授权启动脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
