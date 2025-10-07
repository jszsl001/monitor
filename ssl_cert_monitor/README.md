# SSL Certificate Monitor (ssl-cert-monitor)

一个轻量级的 Shell 脚本，用于监控指定域名的 SSL 证书过期时间，并在证书即将过期时通过电子邮件发送提醒。适用于 Linux 环境，通过 Crontab 定时执行。

## ✨ 功能特性

*   **简单高效**：纯 Shell 脚本实现，无需额外编程语言运行时或数据库。
*   **灵活配置**：所有配置（提醒邮箱、提前提醒天数、监控域名列表）均集成在脚本内部，易于修改。
*   **邮件提醒**：在证书过期前指定天数发送电子邮件通知。
*   **Crontab 集成**：方便地通过 Linux Crontab 设置定时任务，实现自动化监控。
*   **日志记录**：详细记录每次检测的运行状态和结果，便于问题排查。

## 📂 文件结构

```
ssl_cert_monitor/
├── check_certs.sh          # 核心监控脚本 (包含所有配置)
└── ssl_cert_monitor.log    # 脚本运行日志
```

## ⚙️ 配置说明

打开 `check_certs.sh` 文件，您可以在脚本顶部找到并修改以下配置项：

```bash
# --- 全局配置 ---
# 接收提醒的邮箱地址，多个邮箱用逗号分隔
RECIPIENT_EMAIL="your_email@example.com"
# 提前多少天发送提醒
WARNING_DAYS=30

# --- 域名列表 ---
# 需要监控的域名列表，格式为 "domain.com:port" 或 "domain.com" (默认端口443)
DOMAIN_LIST=(
    "example.com:443"
    "google.com"
    "another-domain.net"
)
```

*   **`RECIPIENT_EMAIL`**：将 `"your_email@example.com"` 替换为您实际的邮箱地址。如果您需要发送给多个收件人，可以使用逗号分隔，例如 `"email1@example.com,email2@example.com"`。
*   **`WARNING_DAYS`**：设置一个整数值，表示在证书过期前多少天开始发送提醒邮件。
*   **`DOMAIN_LIST`**：这是一个 Shell 数组，用于列出所有需要监控的域名。
    *   每个域名条目应使用双引号包裹。
    *   如果域名使用标准的 HTTPS 端口（443），只需填写域名，例如 `"google.com"`。
    *   如果域名使用非标准端口，请使用 `域名:端口` 的格式，例如 `"example.com:8443"`。

## 🚀 安装与部署

1.  **上传项目文件：**
    将 `ssl_cert_monitor` 整个目录上传到您的 Linux 服务器上。建议放置在一个固定的位置，例如 `/opt/ssl_cert_monitor/`。

2.  **赋予脚本执行权限：**
    进入 `ssl_cert_monitor` 目录，并执行以下命令赋予 `check_certs.sh` 脚本执行权限：
    ```bash
    cd /opt/ssl_cert_monitor/ # 替换为您的实际路径
    chmod +x check_certs.sh
    ```

3.  **安装邮件发送工具 (如果尚未安装)：**
    脚本使用 `mail` 命令发送邮件。请确保您的 Linux 服务器上安装了 `mailutils` (Debian/Ubuntu) 或 `mailx` (CentOS/RHEL) 等邮件发送工具。
    *   **Debian/Ubuntu:**
        ```bash
        sudo apt-get update
        sudo apt-get install mailutils
        ```
    *   **CentOS/RHEL:**
        ```bash
        sudo yum install mailx
        ```
    您可能还需要配置邮件服务器（如 Postfix 或 Sendmail），以允许脚本通过本地邮件代理发送邮件。

## 💡 使用方法 (Crontab 定时任务)

为了实现自动化监控，您需要设置一个 Crontab 定时任务来定期执行 `check_certs.sh` 脚本。

1.  **打开 Crontab 编辑器：**
    ```bash
    crontab -e
    ```

2.  **添加定时任务：**
    在打开的文件末尾添加一行。以下示例表示每天凌晨 2 点执行脚本：
    ```bash
    0 2 * * * /opt/ssl_cert_monitor/check_certs.sh >> /opt/ssl_cert_monitor/ssl_cert_monitor.log 2>&1
    ```
    *   请将 `/opt/ssl_cert_monitor/` 替换为您的脚本实际路径。
    *   `>> /opt/ssl_cert_monitor/ssl_cert_monitor.log 2>&1` 会将脚本的所有输出（包括标准输出和错误输出）重定向到日志文件，方便您查看。
    *   您可以根据需要调整 `0 2 * * *` 部分来改变执行频率（例如，`0 */6 * * *` 表示每 6 小时执行一次）。

## 📄 日志查看

脚本的运行日志会记录在 `ssl_cert_monitor.log` 文件中。您可以使用 `cat`、`tail` 或 `less` 等命令查看日志：

```bash
tail -f /opt/ssl_cert_monitor/ssl_cert_monitor.log
```

## ⚠️ 注意事项

*   确保您的服务器可以访问需要监控的域名（网络连通性）。
*   `openssl` 命令必须可用。
*   邮件发送功能依赖于系统邮件工具的正确配置。
*   `date` 命令的语法可能因 Linux 发行版而异，脚本已尝试兼容 GNU `date` 和 BSD `date`。

## 🤝 贡献

欢迎提交 Pull Request 或报告 Bug。

## 📄 许可证

本项目采用 MIT 许可证。
