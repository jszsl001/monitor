# Website Availability Monitor (website-availability-monitor)

一个轻量级的 Shell 脚本，用于监控指定 URL 的可访问性。它会定期发送 HTTP 请求，检查网站是否可访问以及返回的 HTTP 状态码是否符合预期。如果网站出现异常，将通过电子邮件发送提醒。适用于 Linux 环境，通过 Crontab 定时执行。

## ✨ 功能特性

*   **简单高效**：纯 Shell 脚本实现，无需额外编程语言运行时。
*   **灵活配置**：所有配置（提醒邮箱、监控 URL 列表、期望状态码、超时时间）均集成在脚本内部，易于修改。
*   **邮件提醒**：在网站不可访问或返回非预期状态码时发送电子邮件通知。
*   **Crontab 集成**：方便地通过 Linux Crontab 设置定时任务，实现自动化监控。
*   **日志记录**：详细记录每次检测的运行状态和结果，便于问题排查。

## 📂 文件结构

```
website-availability-monitor/
├── check_website_status.sh          # 核心监控脚本 (包含所有配置)
└── website_availability_monitor.log # 脚本运行日志
```

## ⚙️ 配置说明

打开 `check_website_status.sh` 文件，您可以在脚本顶部找到并修改以下配置项：

```bash
# --- 全局配置 ---
# 接收提醒的邮箱地址，多个邮箱用逗号分隔
RECIPIENT_EMAIL="your_email@example.com"
# HTTP 请求超时时间 (秒)
TIMEOUT=10
# 期望的 HTTP 状态码 (例如 200, 301, 302)。多个用逗号分隔，留空表示任何 2xx/3xx 状态码都视为成功
EXPECTED_STATUS_CODES="200"

# --- URL 列表 ---
# 需要监控的 URL 列表
URL_LIST=(
    "https://example.com"
    "https://google.com"
    "https://another-website.net"
)
```

*   **`RECIPIENT_EMAIL`**：将 `"your_email@example.com"` 替换为您实际的邮箱地址。如果您需要发送给多个收件人，可以使用逗号分隔，例如 `"email1@example.com,email2@example.com"`。
*   **`TIMEOUT`**：设置 HTTP 请求的超时时间（秒）。如果在此时间内未收到响应，则视为请求失败。
*   **`EXPECTED_STATUS_CODES`**：设置一个或多个期望的 HTTP 状态码，多个状态码用逗号分隔（例如 `"200,301,302"`）。如果留空，则任何 2xx 或 3xx 的状态码都将被视为成功。
*   **`URL_LIST`**：这是一个 Shell 数组，用于列出所有需要监控的 URL。每个 URL 条目应使用双引号包裹。

## 🚀 安装与部署

1.  **上传项目文件：**
    将 `website-availability-monitor` 整个目录上传到您的 Linux 服务器上。建议放置在一个固定的位置，例如 `/opt/monitor/website-availability-monitor/`。

2.  **赋予脚本执行权限：**
    进入 `website-availability-monitor` 目录，并执行以下命令赋予 `check_website_status.sh` 脚本执行权限：
    ```bash
    cd /opt/monitor/website-availability-monitor/ # 替换为您的实际路径
    chmod +x check_website_status.sh
    ```

3.  **安装 `curl` 工具 (如果尚未安装)：**
    脚本使用 `curl` 命令发送 HTTP 请求。请确保您的 Linux 服务器上安装了 `curl` 工具。
    *   **Debian/Ubuntu:**
        ```bash
        sudo apt-get update
        sudo apt-get install curl
        ```
    *   **CentOS/RHEL:**
        ```bash
        sudo yum install curl
        ```

4.  **安装邮件发送工具 (如果尚未安装)：**
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

为了实现自动化监控，您需要设置一个 Crontab 定时任务来定期执行 `check_website_status.sh` 脚本。

1.  **打开 Crontab 编辑器：**
    ```bash
    crontab -e
    ```

2.  **添加定时任务：**
    在打开的文件末尾添加一行。以下示例表示每 5 分钟执行脚本：
    ```bash
    */5 * * * * /opt/monitor/website-availability-monitor/check_website_status.sh >> /opt/monitor/website-availability-monitor/website_availability_monitor.log 2>&1
    ```
    *   请将 `/opt/monitor/website-availability-monitor/` 替换为您的脚本实际路径。
    *   `>> /opt/monitor/website-availability-monitor/website_availability_monitor.log 2>&1` 会将脚本的所有输出（包括标准输出和错误输出）重定向到日志文件，方便您查看。
    *   您可以根据需要调整 `*/5 * * * *` 部分来改变执行频率。

## 📄 日志查看

脚本的运行日志会记录在 `website_availability_monitor.log` 文件中。您可以使用 `cat`、`tail` 或 `less` 等命令查看日志：

```bash
tail -f /opt/monitor/website-availability-monitor/website_availability_monitor.log
```

## ⚠️ 注意事项

*   确保您的服务器可以访问需要监控的 URL（网络连通性）。
*   `curl` 命令必须可用。
*   邮件发送功能依赖于系统邮件工具的正确配置。

## 🤝 贡献

欢迎提交 Pull Request 或报告 Bug。

## 📄 许可证

本项目采用 MIT 许可证。
