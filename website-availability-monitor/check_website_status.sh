#!/bin/bash

# 网站可访问性监控脚本

# --- 配置变量 ---
LOG_FILE="website_availability_monitor.log"

# --- 全局配置 ---
# 接收提醒的邮箱地址，多个邮箱用逗号分隔
RECIPIENT_EMAIL="your_email@example.com"
# HTTP 请求超时时间 (秒)
TIMEOUT=30
# 期望的 HTTP 状态码 (例如 200, 301, 302)。多个用逗号分隔，留空表示任何 2xx/3xx 状态码都视为成功
EXPECTED_STATUS_CODES="200"

# --- URL 列表 ---
# 需要监控的 URL 列表
URL_LIST=(
    "https://example.com"
    "https://google.com"
)

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

# --- 函数：检查 URL 状态 ---
check_url_status() {
    local url=$1
    local expected_codes=$2
    local timeout=$3
    local status_code=""
    local curl_output=""

    # 使用 curl 发送请求，获取 HTTP 状态码和错误信息
    # -o /dev/null 丢弃响应体
    # -s 静默模式
    # -w "%{http_code}" 打印 HTTP 状态码
    # --connect-timeout 设置连接超时
    # -m 设置总超时
    curl_output=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout "$timeout" -m "$timeout" "$url" 2>&1)
    status_code=$(echo "$curl_output" | tail -n 1) # 提取最后一行作为状态码

    if [[ "$status_code" =~ ^[0-9]{3}$ ]]; then # 检查是否是有效的HTTP状态码
        # 检查状态码是否在期望列表中
        IFS=',' read -ra codes_array <<< "$expected_codes"
        is_expected=false
        if [ -z "$expected_codes" ]; then # 如果没有指定期望状态码，则2xx/3xx都算成功
            if [[ "$status_code" =~ ^(2|3)[0-9]{2}$ ]]; then
                is_expected=true
            fi
        else
            for code in "${codes_array[@]}"; do
                if [ "$status_code" == "$code" ]; then
                    is_expected=true
                    break
                fi
            done
        fi

        if [ "$is_expected" = true ]; then
            echo "SUCCESS:$status_code"
        else
            echo "FAILURE:$status_code"
        fi
    else
        # curl 失败，可能是连接超时、DNS 解析失败等
        echo "FAILURE:CURL_ERROR - $curl_output"
    fi
}

# --- 主逻辑 ---
main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 网站可访问性监控脚本开始运行。" >> "$LOG_FILE"

    if [ -z "$RECIPIENT_EMAIL" ] || [ -z "$TIMEOUT" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: 全局配置 RECIPIENT_EMAIL 或 TIMEOUT 缺失。" >> "$LOG_FILE"
        exit 1
    fi

    if [ ${#URL_LIST[@]} -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: URL 列表为空，没有需要检测的网站。" >> "$LOG_FILE"
    fi

    for url in "${URL_LIST[@]}"; do
        if [ -z "$url" ]; then
            continue
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 正在检测 URL $url ..." >> "$LOG_FILE"

        result=$(check_url_status "$url" "$EXPECTED_STATUS_CODES" "$TIMEOUT")
        status=$(echo "$result" | cut -d':' -f1)
        details=$(echo "$result" | cut -d':' -f2-)

        if [ "$status" == "SUCCESS" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: URL $url 访问正常，状态码：$details" >> "$LOG_FILE"
        else
            subject="网站可访问性提醒：$url 访问异常"
            message="URL $url 访问异常！\n详细信息：$details\n请尽快检查！"
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $message" >> "$LOG_FILE"
            send_email_alert "$RECIPIENT_EMAIL" "$subject" "$message"
        fi
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: 网站可访问性监控脚本运行结束。" >> "$LOG_FILE"
}

# 执行主逻辑
main
