# SmartMobileAutomation - 一键运行脚本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SmartMobileAutomation" -ForegroundColor Cyan
Write-Host "  通用 Android App UI 自动化框架" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Python
Write-Host "[1/5] 检查Python环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "错误: 未找到Python，请先安装Python 3.7+" -ForegroundColor Red
    Write-Host "下载地址: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 检查配置文件
Write-Host "[2/5] 检查配置文件..." -ForegroundColor Yellow
if (Test-Path "config.yaml") {
    Write-Host "配置文件存在: config.yaml" -ForegroundColor Green
    try {
        # 尝试读取YAML配置（简单检查）
        $configContent = Get-Content "config.yaml" -Raw
        if ($configContent -match "package_name" -and $configContent -match "activity_name") {
            Write-Host "  配置文件格式正确" -ForegroundColor Green
        } else {
            Write-Host "  警告: 配置文件可能缺少必要字段" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  警告: 无法读取配置文件" -ForegroundColor Yellow
    }
} elseif (Test-Path "config.example.yaml") {
    Write-Host "错误: 配置文件不存在" -ForegroundColor Red
    Write-Host "请复制 config.example.yaml 为 config.yaml 并配置" -ForegroundColor Yellow
    Write-Host "  cp config.example.yaml config.yaml" -ForegroundColor White
    exit 1
} else {
    Write-Host "错误: 未找到配置文件模板" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 检查Python依赖
Write-Host "[3/5] 检查Python依赖..." -ForegroundColor Yellow
$requiredDeps = @("appium", "selenium", "yaml")
$missingDeps = @()

foreach ($dep in $requiredDeps) {
    try {
        if ($dep -eq "yaml") {
            $result = python -c "import yaml; print('ok')" 2>&1
        } else {
            $result = python -c "import $dep; print('ok')" 2>&1
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ $dep: 已安装" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $dep: 未安装" -ForegroundColor Red
            $missingDeps += $dep
        }
    } catch {
        Write-Host "  ❌ $dep: 未安装" -ForegroundColor Red
        $missingDeps += $dep
    }
}

if ($missingDeps.Count -gt 0) {
    Write-Host ""
    Write-Host "缺少以下依赖，请运行：" -ForegroundColor Yellow
    Write-Host "  pip install -r requirements.txt" -ForegroundColor White
    Write-Host ""
    Write-Host "按任意键退出..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
Write-Host ""

# 检查ADB设备
Write-Host "[4/5] 检查设备连接..." -ForegroundColor Yellow
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdk\platform-tools\adb.exe"

# 尝试多个可能的ADB路径
$adbPaths = @(
    "$sdk\platform-tools\adb.exe",
    "C:\platform-tools\adb.exe",
    "adb.exe"
)

$adbFound = $false
foreach ($adbPath in $adbPaths) {
    if (Test-Path $adbPath) {
        $adb = $adbPath
        $adbFound = $true
        break
    }
    # 尝试在PATH中查找
    try {
        $adbVersion = & adb version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $adb = "adb"
            $adbFound = $true
            break
        }
    } catch {
        continue
    }
}

if ($adbFound) {
    try {
        & $adb kill-server 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        & $adb start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        $devices = & $adb devices
        $deviceLines = $devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if ($deviceLines.Count -gt 0) {
            Write-Host "设备已连接" -ForegroundColor Green
            foreach ($line in $deviceLines) {
                $deviceId = ($line -split "\s+")[0]
                Write-Host "  设备: $deviceId" -ForegroundColor Gray
            }
        } else {
            Write-Host "警告: 未检测到设备" -ForegroundColor Yellow
            Write-Host "请先连接设备（USB或WiFi），参考: 使用指南\连接步骤.md" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "警告: 无法检查设备连接" -ForegroundColor Yellow
    }
} else {
    Write-Host "警告: 未找到ADB工具" -ForegroundColor Yellow
    Write-Host "请安装Android SDK Platform Tools，参考: 使用指南\安装指南.md" -ForegroundColor Yellow
}
Write-Host ""

# 检查Appium服务器
Write-Host "[5/5] 检查Appium服务器..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:4723/status" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "Appium服务器正在运行" -ForegroundColor Green
} catch {
    Write-Host "Appium服务器未运行" -ForegroundColor Red
    Write-Host ""
    Write-Host "请在新窗口中运行以下命令启动Appium服务器：" -ForegroundColor Cyan
    Write-Host "  appium --port 4723" -ForegroundColor White
    Write-Host ""
    Write-Host "按任意键继续（确认Appium服务器已启动）..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
Write-Host ""

# 显示说明
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "框架特性：" -ForegroundColor Yellow
Write-Host "  ✅ 智能阶段控制" -ForegroundColor Green
Write-Host "  ✅ 完全可配置的元素定位器" -ForegroundColor Green
Write-Host "  ✅ 支持任意 Android App" -ForegroundColor Green
Write-Host ""
Write-Host "请确认：" -ForegroundColor Yellow
Write-Host "1. 目标 App 已安装并登录（如需要）" -ForegroundColor White
Write-Host "2. Appium服务器正在运行" -ForegroundColor White
Write-Host "3. 配置文件 config.yaml 已正确设置" -ForegroundColor White
Write-Host "4. 已获取目标 App 的元素定位器" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  重要提醒：" -ForegroundColor Yellow
Write-Host "  请遵守目标 App 的用户协议" -ForegroundColor White
Write-Host "  本工具仅用于个人效率提升" -ForegroundColor White
Write-Host ""
Write-Host "按任意键开始运行..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# 运行脚本
Write-Host "正在启动自动化框架..." -ForegroundColor Green
Write-Host ""
python smart_mobile_automation.py

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "脚本运行完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

