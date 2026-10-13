@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM ===========================================================================
REM  Katabump 自动续期 —— Windows 计划任务一键安装
REM
REM  用法：
REM    双击运行           -> 以当前用户身份安装（仅登录时运行，无需管理员）
REM    install_task.bat /system  -> 以 SYSTEM 身份安装（注销后也能运行，需管理员）
REM
REM  卸载：schtasks /delete /tn "KatabumpAutoRenew" /f
REM ===========================================================================

set "TASK_NAME=KatabumpAutoRenew"
set "START_TIME=12:30"
set "SCRIPT_PATH=%~dp0run_renew.ps1"

echo ============================================================
echo   Katabump 自动续期 - 计划任务安装
echo ============================================================
echo.

REM --- 前置检查：确认执行体脚本存在 ---
if not exist "%SCRIPT_PATH%" (
    echo [错误] 找不到 run_renew.ps1
    echo        预期位置: %SCRIPT_PATH%
    exit /b 1
)

REM --- 检测管理员权限 ---
net session >nul 2>&1
if %errorlevel% equ 0 (set "IS_ADMIN=1") else (set "IS_ADMIN=0")

REM --- 决定运行身份 ---
if /i "%~1"=="/system" (
    if "!IS_ADMIN!"=="0" (
        echo [错误] 使用 /system 参数需要管理员权限。
        echo        请右键点击本文件 -^> "以管理员身份运行"。
        echo.
        pause
        exit /b 1
    )
    set "RUN_MODE=SYSTEM"
    set "IDENTITY_ARGS=/RU SYSTEM /RL HIGHEST"
) else (
    set "RUN_MODE=当前用户"
    set "IDENTITY_ARGS=/IT"
)

echo 任务名称 : %TASK_NAME%
echo 执行时间 : 每天 %START_TIME%
echo 运行身份 : !RUN_MODE!
echo 执行脚本 : %SCRIPT_PATH%
echo.

REM --- 创建/覆盖计划任务 ---
REM 说明：/tr 中的 \" 是转义写法，用于让 schtasks 正确解析带空格的路径
schtasks /Create ^
    /TN "%TASK_NAME%" ^
    /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_PATH%\"" ^
    /SC DAILY ^
    /ST %START_TIME% ^
    !IDENTITY_ARGS! ^
    /F

if %errorlevel% neq 0 (
    echo.
    echo [失败] 计划任务创建失败，请检查上方错误信息。
    pause
    exit /b 1
)

REM --- 调整任务设置：错过后补跑 + 允许电池供电时运行 ---
REM StartWhenAvailable 非常关键：如果 12:30 时电脑关机/休眠，开机后会自动补跑一次。
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { $s = (Get-ScheduledTask -TaskName '%TASK_NAME%' -ErrorAction Stop).Settings; $s.StartWhenAvailable = $true; $s.DisallowStartIfOnBatteries = $false; $s.StopIfGoingOnBatteries = $false; $s.ExecutionTimeLimit = 'PT2H'; Set-ScheduledTask -TaskName '%TASK_NAME%' -Settings $s | Out-Null; Write-Host '[OK] 任务策略已优化（支持错过补跑、电池供电可运行）' } catch { Write-Host '[警告] 任务策略调整失败（不影响基本运行）:' $_.Exception.Message }"

echo.
echo ============================================================
echo   安装完成！
echo ============================================================
echo.
echo   下次运行：每天 %START_TIME%
echo   日志目录：%~dp0logs\
echo   截图目录：%~dp0photo\
echo.
echo   常用命令：
echo     立即测试运行 : schtasks /run /tn "%TASK_NAME%"
echo     查看任务状态 : schtasks /query /tn "%TASK_NAME%" /v /fo list
echo     卸载本任务   : schtasks /delete /tn "%TASK_NAME%" /f
echo.
echo   提示：首次运行前请确认 login.json 已配置好账号密码。
echo.

choice /c YN /n /m "是否立即运行一次进行测试？(Y/N) "
if errorlevel 2 goto :done
if errorlevel 1 (
    echo.
    echo 正在触发任务...
    schtasks /run /tn "%TASK_NAME%"
    echo 任务已触发。约 1-2 分钟后可查看日志：%~dp0logs\
)

:done
echo.
pause
endlocal
