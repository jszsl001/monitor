#!/bin/bash

# 证书监控脚本

# --- 配置变量 ---
LOG_FILE="ssl_cert_monitor.log"

# --- 全局配置 ---
# 接收提醒的邮箱地址，多个邮箱用逗号分隔
RECIPIENT_EMAIL="jszsl001@163.com"
# 提前多少天发送提醒
WARNING_DAYS=180

# --- 域名列表 ---
# 需要监控的域名列表，格式为 "domain.com:port" 或 "domain.com" (默认端口443)
DOMAIN_LIST=(
    "proxy.zheguyunproxy.asia:443"
)

# --- 函数：获取证书过期日期 ---
get_cert_expiry_date() {
    local domain=$1
    local port=${2:-443} # 默认端口为443

    # 使用openssl获取证书信息
    # 注意：-servername 参数对于SNI是必需的
    expiry_date_str=$(echo | openssl s_client -servername "$domain" -connect "$domain":"$port" 2>/dev/null | \
                      openssl x509 -noout -enddate 2>/dev/null | \
                      cut -d'=' -f2)

    if [ -z "$expiry_date_str" ]; then
        echo "ERROR: 无法获取 $domain 证书过期日期。" >> "$LOG_FILE"
        echo "" # 返回空字符串表示失败
    else
        # 将日期字符串转换为Unix时间戳
        # 注意：不同的系统可能需要不同的date命令格式
        # 尝试使用GNU date或BSD date
        if date --version &>/dev/null; then # GNU date
            date -d "$expiry_date_str" +%s
        else # BSD date (macOS)
            date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date_str" +%s 2>/dev/null || \
            date -j -f "%b %d %H:%M:%S %Y GMT" "$expiry_date_str" +%s 2>/dev/null || \
            date -j -f "%b %d %H:%M:%S %Y" "$expiry_date_str" +%s 2>/dev/null
        fi
    fi
}

# --- 函数：发送邮件提醒 ---
send_email_alert() {
    local recipient=$1
    local subject=$2
    local message=$3

    echo -e "$message" | mail -s "$subject" "$recipient"
    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 邮件已发送至 $recipient，主题：$subject" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: 邮件发送失败至 $recipient，主题：$subject" >> "$LOG_FILE"
    fi
}

# --- 主逻辑 ---
main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 证书监控脚本开始运行。" >> "$LOG_FILE"

    if [ -z "$RECIPIENT_EMAIL" ] || [ -z "$WARNING_DAYS" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: 全局配置 RECIPIENT_EMAIL 或 WARNING_DAYS 缺失。" >> "$LOG_FILE"
        exit 1
    fi

    # 获取当前时间戳
    CURRENT_TIMESTAMP=$(date +%s)
    # 计算提醒阈值时间戳
    WARNING_THRESHOLD_TIMESTAMP=$((CURRENT_TIMESTAMP + WARNING_DAYS * 24 * 60 * 60))

    if [ ${#DOMAIN_LIST[@]} -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: 域名列表为空，没有需要检测的域名。" >> "$LOG_FILE"
    fi

    for entry in "${DOMAIN_LIST[@]}"; do
        if [ -z "$entry" ]; then
            continue
        fi

        # 解析域名和端口
        IFS=':' read -r domain port <<< "$entry"
        port=${port:-443} # 如果未指定端口，默认为443

        echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 正在检测域名 $domain (端口: $port)..." >> "$LOG_FILE"

        EXPIRY_TIMESTAMP=$(get_cert_expiry_date "$domain" "$port")

        if [ -z "$EXPIRY_TIMESTAMP" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: 无法获取 $domain 的证书过期时间，跳过。" >> "$LOG_FILE"
            continue
        fi

        # 将过期时间戳转换为可读日期
        EXPIRY_DATE=$(date -d "@$EXPIRY_TIMESTAMP" '+%Y-%m-%d %H:%M:%S')

        if [ "$EXPIRY_TIMESTAMP" -lt "$WARNING_THRESHOLD_TIMESTAMP" ]; then
            # 证书即将过期
            days_left=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / (24 * 60 * 60) ))
            subject="SSL证书过期提醒：$domain"
            message="域名 $domain 的SSL证书将在 $EXPIRY_DATE 过期，剩余 $days_left 天。请尽快处理！"
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: $message" >> "$LOG_FILE"
            send_email_alert "$RECIPIENT_EMAIL" "$subject" "$message"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 域名 $domain 的证书在 $EXPIRY_DATE 过期，无需提醒。" >> "$LOG_FILE"
        fi
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 证书监控脚本运行结束。" >> "$LOG_FILE"
}

# 执行主逻辑
main
