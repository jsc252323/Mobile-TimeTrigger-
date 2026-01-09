@echo off
chcp 65001 >nul
title SmartMobileAutomation - 通用 Android App UI 自动化框架

echo ========================================
echo   SmartMobileAutomation
echo   通用 Android App UI 自动化框架
echo ========================================
echo.

REM 检查Python
echo [1/4] 检查Python环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到Python，请先安装Python 3.7+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)
python --version
echo.

REM 检查配置文件
echo [2/4] 检查配置文件...
if not exist "config.yaml" (
    if exist "config.example.yaml" (
        echo 配置文件不存在，正在从示例文件创建...
        copy "config.example.yaml" "config.yaml" >nul
        echo 已创建 config.yaml，请编辑配置文件后重新运行
        echo.
        echo 按任意键打开配置文件...
        pause >nul
        notepad config.yaml
        exit /b 0
    ) else (
        echo 错误: 配置文件不存在，且找不到 config.example.yaml
        pause
        exit /b 1
    )
)
echo 配置文件存在
echo.

REM 检查ADB设备
echo [3/4] 检查设备连接...
set "sdk=%LOCALAPPDATA%\Android\Sdk"
set "adb=%sdk%\platform-tools\adb.exe"

if exist "%adb%" (
    "%adb%" kill-server >nul 2>&1
    timeout /t 1 /nobreak >nul
    "%adb%" start-server >nul 2>&1
    timeout /t 2 /nobreak >nul
    
    "%adb%" devices | findstr "device$" >nul
    if errorlevel 1 (
        echo 警告: 未检测到设备
        echo 请先连接设备（USB或WiFi）
        echo 参考: 使用指南\连接步骤.md
    ) else (
        echo 设备已连接
        "%adb%" devices | findstr "device$"
    )
) else (
    echo 警告: 未找到ADB
    echo 请确保已安装Android SDK或Android Studio
)
echo.

REM 检查Appium服务器
echo [4/4] 检查Appium服务器...
curl -s http://127.0.0.1:4723/status >nul 2>&1
if errorlevel 1 (
    echo Appium服务器未运行
    echo.
    echo 请在新窗口中运行以下命令启动Appium服务器：
    echo   appium --port 4723
    echo.
    echo 按任意键继续（确认Appium服务器已启动）...
    pause >nul
) else (
    echo Appium服务器正在运行
)
echo.

REM 显示说明
echo ========================================
echo 核心功能：
echo   ✅ 智能阶段控制 - 根据目标时间自动调整操作频率
echo   ✅ 完全可配置 - 通过YAML配置文件定义所有元素定位器
echo   ✅ 通用框架 - 支持任意Android App
echo   ✅ 智能重试 - 自动重试机制，提高成功率
echo.
echo 使用说明：
echo   1. 确保目标App已安装并登录
echo   2. 确保Appium服务器正在运行
echo   3. 确保配置文件已正确设置
echo   4. 确保设备已正确连接
echo.
echo 提示: 按 Ctrl+C 可随时停止脚本
echo ========================================
echo.
echo 按任意键开始运行...
pause >nul
echo.

REM 运行脚本
echo 正在启动自动化框架...
echo.
python smart_mobile_automation.py

echo.
echo ========================================
echo 脚本运行完成
echo ========================================
pause

