#!/bin/bash
set -e

MODE=$1
shift 1

NIC=${NIC:-eth0}
TCP_PORT=${TCP_PORT:-20001}

cleanup_server() {
    echo "[Info] 正在清理 Server 端的 iptables 规则..."
    # 清理 NAT 和 RST 阻断
    iptables -t nat -D PREROUTING -p tcp -i $NIC --dport $TCP_PORT -j DNAT --to-destination 192.168.201.2 2>/dev/null || true
    iptables -D OUTPUT -p tcp -o $NIC --sport $TCP_PORT --tcp-flags RST RST -j DROP 2>/dev/null || true
    # 【新增】清理 FORWARD 放行规则
    iptables -D FORWARD -i $NIC -o tun0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i tun0 -o $NIC -j ACCEPT 2>/dev/null || true
}

cleanup_client() {
    echo "[Info] 正在清理 Client 端的 iptables 规则..."
    iptables -t nat -D POSTROUTING -o $NIC -j MASQUERADE 2>/dev/null || true
    iptables -D OUTPUT -p tcp -o $NIC --dport $TCP_PORT --tcp-flags RST RST -j DROP 2>/dev/null || true
    # 【新增】清理 FORWARD 放行规则 (对于客户端同样适用)
    iptables -D FORWARD -i $NIC -o tun0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i tun0 -o $NIC -j ACCEPT 2>/dev/null || true
}

if [ "$MODE" = "server" ]; then
    echo "[Info] 初始化 Phantun Server 模式..."
    cleanup_server

    iptables -t nat -A PREROUTING -p tcp -i $NIC --dport $TCP_PORT -j DNAT --to-destination 192.168.201.2
    iptables -A OUTPUT -p tcp -o $NIC --sport $TCP_PORT --tcp-flags RST RST -j DROP
    # 【新增】强制放行网卡与 TUN 设备间的双向转发
    iptables -I FORWARD -i $NIC -o tun0 -j ACCEPT
    iptables -I FORWARD -i tun0 -o $NIC -j ACCEPT

    trap cleanup_server EXIT INT TERM

    echo "[Info] 启动 phantun_server..."
    /usr/local/bin/phantun_server "$@" &
    PHANTUN_PID=$!

elif [ "$MODE" = "client" ]; then
    echo "[Info] 初始化 Phantun Client 模式..."
    cleanup_client

    iptables -t nat -A POSTROUTING -o $NIC -j MASQUERADE
    iptables -A OUTPUT -p tcp -o $NIC --dport $TCP_PORT --tcp-flags RST RST -j DROP
    # 【新增】强制放行网卡与 TUN 设备间的双向转发
    iptables -I FORWARD -i $NIC -o tun0 -j ACCEPT
    iptables -I FORWARD -i tun0 -o $NIC -j ACCEPT

    trap cleanup_client EXIT INT TERM

    echo "[Info] 启动 phantun_client..."
    /usr/local/bin/phantun_client "$@" &
    PHANTUN_PID=$!

else
    echo "[Error] 未知的运行模式"
    exit 1
fi

wait $PHANTUN_PID
