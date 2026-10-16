# Katabump Server Auto-Renewal Tool

[English Version](README_EN.md) | [中文说明](README.md)

这是一个用于自动续期 Katabump 服务器的自动化脚本。它利用 Playwright 和 CDP (Chrome DevTools Protocol) 技术来模拟用户操作，能够有效绕过 Cloudflare Turnstile 验证码，确保持续的服务器服务。

支持 **Windows 本地运行** 和 **GitHub Actions 云端运行**。

## ✨ 特性

- **智能过盾**: 通过 CDP 协议模拟真实鼠标轨迹和点击行为，结合屏幕坐标伪造，高成功率绕过 Cloudflare Turnstile。
- **自动重试**: 内置严格的验证重试机制，如果验证失败会自动重启验证流程。
- **多用户支持**: 支持配置多个账号批量续期。
- **云端/本地**: 既可以在本地电脑跑，也可以利用 GitHub Actions 每天定时自动跑。

---

## 🚀 GitHub Actions 云端运行 (推荐)

这是最省心的方式，配置一次即可每天自动执行。

1. **Fork 本仓库** 到你的 GitHub 账号。
2. 进入你的仓库，点击 **Settings** -> **Secrets and variables** -> **Actions**。
3. 点击 **New repository secret**，添加一个名为 `USERS_JSON` 的 Secret。
4. **Value** 的格式必须是 JSON 数组（请尽量压缩为一行）：
   ```json
   [{"username": "your_email@example.com", "password": "your_password"}, {"username": "another@example.com", "password": "pwd"}]
   ```
5. **(可选) 配置代理**:
   如果 GitHub Actions 的 IP 被屏蔽，或者你想使用特定的 IP 访问，可以添加名为 `HTTP_PROXY` 的 Secret。
   - **格式**:
     - 无认证: `http://ip:port`
     -带认证: `http://username:password@ip:port`
   - **说明**: 脚本会自动检测代理有效性，如果支持认证会自动处理。默认不启用。

6. **(可选) Telegram 消息推送**:
   如果你希望在续期成功、失败或跳过时收到 Telegram 通知（包含截图），请配置以下 Secret：
   - `TG_BOT_TOKEN`: 你的 Telegram Bot Token (从 @BotFather 获取)。
   - `TG_CHAT_ID`: 你的 Chat ID (用户 ID 或群组 ID)。
   > 如果未配置，脚本将跳过发送通知。

7. 保存后，进入 **Actions** 页面，启用 Workflow。它会在**每天北京时间 08:00 (UTC 00:00)** 自动运行。
8. 你也可以手动点击 "Run workflow" 立即测试。

### 运行结果与截图

- **运行日志**: 在 Actions 中的 `Run Renew Script` 步骤查看。
- **截图留存**: 每次运行（无论成功与否），通过 `Upload Screenshots` 步骤自动上传截图。
  - 你可以在 Workflow 运行详情页的 **Artifacts** 区域下载 `screenshots` 压缩包。
  - 每个账号对应一张截图（`username.png`），方便确认状态。

---

## 💻 Windows 本地运行指南

如果你想在本地观察运行过程或进行调试，请按以下步骤操作。

### 1. 环境准备

确保你已经安装了 [Node.js](https://nodejs.org/) (建议版本 v18+)。

### 2. 安装依赖

在项目根目录打开终端 (PowerShell 或 CMD)，运行：

```bash
npm install
```

### 3. 配置账号

项目中有一个 `login.json.template` 模板文件。

1. 将其**重命名**为 `login.json`。
2. 用记事本或编辑器打开，填入你的账号密码：
   ```json
   [
       {
           "username": "myemail@gmail.com",
           "password": "mypassword123"
       }
   ]
   ```

   > **注意**: `login.json` 已被加入 `.gitignore`，不会被上传到 GitHub，请放心使用。
   >

### 4. 运行参数

**Chrome 路径不用手动配置**：`renew.js` 会依次探测 `CHROME_PATH` 环境变量 → `%LOCALAPPDATA%` → `Program Files` → `Program Files (x86)`。只有当 Chrome 装在非标准位置时，才需要显式指定：

```powershell
$env:CHROME_PATH = '<你的 chrome.exe 完整路径>'
node renew.js
```

**浏览器数据目录**（`USER_DATA_DIR`，即项目根目录下的 `ChromeData_Katabump`）：

* 存放脚本运行产生的缓存、Cookie、登录状态等。
* **作用**: 让登录状态保持更久，不需要每次运行都重新输入密码。
* **能不能删？**: **可以删**。想要彻底重置状态就删掉这个文件夹，脚本下次运行会自动重建。

**运行模式**（默认有头可见，可用环境变量覆盖）：

| 变量 | 效果 |
| --- | --- |
| （不设置） | 弹出可见的 Chrome 窗口，你能看到全部操作过程 |
| `HEADLESS=true` | 纯无头运行，界面上完全看不见 |
| `OFFSCREEN=1` | 仍是有头模式，但窗口被移到屏幕外（定时任务用的就是它） |

> 定时任务为什么选 `OFFSCREEN=1` 而不是 `HEADLESS=true`，见下方「静默运行原理」。

**手动调试**：双击 `start_chrome.bat` 会以调试端口 9222 打开 Chrome，并使用与脚本**完全相同**的 `ChromeData_Katabump` 目录。脚本运行时若发现该实例，会复用它，并在结束时关闭。

### 5. 运行脚本

如果你需要使用代理运行脚本，请设置环境变量 `HTTP_PROXY`：

**Powershell:**
```powershell
$env:HTTP_PROXY="http://user:pass@127.0.0.1:7890"
node renew.js
```

**CMD:**
```cmd
set HTTP_PROXY=http://user:pass@127.0.0.1:7890
node renew.js
```

如果不设置代理，直接运行：
```bash
node renew.js
```

脚本会自动启动 Chrome（如果还没有实例），逐个处理账号，并在根目录下的 `photo/` 文件夹中保存每个账号运行结束时的截图（`账号名.png`）。默认是有头模式，你能看到操作过程；结束时会关闭自己启动的 Chrome，不会在任务栏留下后台窗口。

---

## ⏰ Windows 本地定时运行

不想依赖 GitHub Actions？可以让脚本在你自己的电脑上每天定时自动续期。

### 1. 一键安装计划任务

1. 确认 `login.json` 已配置好账号密码（见下方本地运行指南第 3 步）。
2. **双击运行 `install_task.bat`**，按提示确认即可。
3. 安装完成后，脚本会询问是否**立即测试运行一次**，建议选 `Y` 验证配置是否正确。

默认配置：**每天中午 12:30** 自动执行，以当前用户身份运行，**无需管理员权限**。

> 如果你希望电脑注销后也能执行，请右键 `install_task.bat` →「以管理员身份运行」，并在命令行追加 `/system` 参数：
> ```cmd
> install_task.bat /system
> ```

### 2. 静默运行原理

计划任务执行时**不会弹出可见的 Chrome 窗口**，但底层仍然使用**有头模式**运行（通过 `--window-position=-32000,-32000` 把窗口移到屏幕外）。

> **为什么不直接开 `HEADLESS=true`？**
> Cloudflare Turnstile 对纯无头浏览器有更强的检测机制，过盾成功率会显著下降。这也是云端 Actions 版本使用 `xvfb-run`（虚拟显示器）模拟有头环境的原因。本地方案用「窗口移出屏幕」达到了同样的效果——指纹真实，但用户看不见。

### 3. 日志与排查

| 类型 | 位置 |
| --- | --- |
| 运行日志 | `logs\renew_年月日.log`（自动清理 30 天前的旧日志） |
| 结果截图 | `photo\账号名.png` |

常用命令：

```powershell
# 立即运行一次测试
schtasks /run /tn "KatabumpAutoRenew"

# 查看任务状态与上次运行结果
schtasks /query /tn "KatabumpAutoRenew" /v /fo list

# 卸载定时任务
schtasks /delete /tn "KatabumpAutoRenew" /f
```

### 4. 错过执行怎么办

任务已配置 `StartWhenAvailable`：如果 12:30 时电脑处于关机或休眠状态，**开机后 Windows 会自动补跑一次**，不会因为错过时间点而漏掉续期。

### 5. 需要代理时

编辑 `run_renew.ps1`，取消这两行的注释并填入你的代理地址：

```powershell
$env:HTTP_PROXY = 'http://127.0.0.1:7890'
$env:HTTPS_PROXY = 'http://127.0.0.1:7890'
```

---

## 🛠️ 项目结构

* `renew.js`: Windows 本地运行的主程序。
* `action_renew.js`: 专门用于 GitHub Actions 环境的脚本（适配 Linux/Headless）。
* `run_renew.ps1`: 计划任务的执行体（设置静默环境变量、写日志、调用 `renew.js`）。
* `install_task.bat`: 一键注册 Windows 计划任务的安装脚本。
* `.github/workflows/renew.yml`: GitHub Actions 的定时任务配置文件。
* `login.json`: (需手动创建) 存放本地运行的账号信息。
* `photo/`: 运行截图输出目录。
* `logs/`: 定时任务日志输出目录。
* `start_chrome.bat`: 手动以调试端口 9222 打开 Chrome（与脚本共用同一数据目录）。
