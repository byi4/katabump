<#
    Katabump 自动续期 —— 计划任务执行体
    由 Windows 计划任务 "KatabumpAutoRenew" 调用，也可手动运行做验证。

    手动验证方式：
        powershell -NoProfile -ExecutionPolicy Bypass -File .\run_renew.ps1
    或直接双击 install_task.bat 后选择立即运行。

    日志位置：项目根目录 logs\renew_日期.log
#>

$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# 编码设置（重要）
# ---------------------------------------------------------------------------
# PowerShell 5.1 默认用系统 ANSI 代码页（中文系统为 GBK）解码子进程的 stdout，
# 会导致 node 输出的中文和 emoji 变成乱码（如 "✅" 变成 "鉁?"）。
# 显式设为 UTF-8 才能正确接收 node 的输出。
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogDir    = Join-Path $ScriptDir 'logs'
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir ("renew_{0}.log" -f (Get-Date -Format 'yyyyMMdd'))

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    $line | Out-File -FilePath $LogFile -Append -Encoding utf8
    Write-Host $line
}

Write-Log "===== 任务开始 ====="

# ---------------------------------------------------------------------------
# 环境变量
# ---------------------------------------------------------------------------
# OFFSCREEN=1：保持"有头"模式（真实浏览器特征，更容易通过 Cloudflare Turnstile），
# 但把 Chrome 窗口移到屏幕外，实现静默运行。
# 注意：不要改成 HEADLESS=true —— 纯无头模式容易被 Turnstile 判定为机器人。
$env:OFFSCREEN = '1'

# 需要代理时取消下面两行注释并填入你的地址：
# $env:HTTP_PROXY = 'http://127.0.0.1:7890'
# $env:HTTPS_PROXY = 'http://127.0.0.1:7890'

# ---------------------------------------------------------------------------
# 定位 node.exe（兼容 nvm-windows：node 通过 symlink 暴露）
# ---------------------------------------------------------------------------
function Find-Node {
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    if ($env:NVM_SYMLINK) {
        $p = Join-Path $env:NVM_SYMLINK 'node.exe'
        if (Test-Path $p) { return $p }
    }

    $candidates = @(
        (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\nodejs\node.exe')
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

$nodeExe = Find-Node
if (-not $nodeExe) {
    Write-Log "错误：未找到 node.exe。请确认已安装 Node.js，或在计划任务中手动指定路径。"
    exit 1
}
Write-Log "Node 路径: $nodeExe ($(& $nodeExe -v))"

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
$RenewScript = Join-Path $ScriptDir 'renew.js'
if (-not (Test-Path $RenewScript)) {
    Write-Log "错误：找不到 renew.js（预期位置：$RenewScript）"
    exit 1
}

$LoginJson = Join-Path $ScriptDir 'login.json'
if (-not (Test-Path $LoginJson)) {
    Write-Log "错误：找不到 login.json —— 请复制 login.json.template 为 login.json 并填入账号密码。"
    exit 1
}

# ---------------------------------------------------------------------------
# 执行续期脚本
# ---------------------------------------------------------------------------
$exitCode = 0
Push-Location $ScriptDir
try {
    # *>&1 把所有输出流（含 stderr）合并后逐行写入日志
    & $nodeExe $RenewScript *>&1 | ForEach-Object { Write-Log $_ }
    if ($null -ne $LASTEXITCODE) { $exitCode = $LASTEXITCODE }
} catch {
    Write-Log "执行异常: $_"
    $exitCode = 1
} finally {
    Pop-Location
}

Write-Log "===== 任务结束，退出码 $exitCode ====="

# ---------------------------------------------------------------------------
# 清理 30 天前的旧日志，避免目录无限增长
# ---------------------------------------------------------------------------
Get-ChildItem -Path $LogDir -Filter 'renew_*.log' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

exit $exitCode
