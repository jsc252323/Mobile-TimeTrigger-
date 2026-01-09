# 检查所有依赖是否已安装
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SmartMobileAutomation - 依赖检查工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allOk = $true

# 1. 检查Python
Write-Host "[1/6] 检查Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python 3\.([7-9]|[1-9][0-9])") {
        Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
    } elseif ($pythonVersion -match "Python 3\.[0-6]") {
        Write-Host "❌ Python版本过低: $pythonVersion" -ForegroundColor Red
        Write-Host "   需要Python 3.7+" -ForegroundColor Yellow
        $allOk = $false
    } else {
        Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Python未安装" -ForegroundColor Red
    Write-Host "   请从 https://www.python.org/downloads/ 下载安装" -ForegroundColor Yellow
    $allOk = $false
}
Write-Host ""

# 2. 检查Python依赖
Write-Host "[2/6] 检查Python依赖..." -ForegroundColor Yellow
$pythonDeps = @("appium", "selenium", "yaml")
$missingDeps = @()

foreach ($dep in $pythonDeps) {
    try {
        if ($dep -eq "yaml") {
            $result = python -c "import yaml; print('ok')" 2>&1
        } else {
            $result = python -c "import $dep; print($dep.__version__)" 2>&1
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $dep: 已安装" -ForegroundColor Green
        } else {
            Write-Host "❌ $dep: 未安装" -ForegroundColor Red
            $missingDeps += $dep
            $allOk = $false
        }
    } catch {
        Write-Host "❌ $dep: 未安装" -ForegroundColor Red
        $missingDeps += $dep
        $allOk = $false
    }
}

if ($missingDeps.Count -gt 0) {
    Write-Host ""
    Write-Host "缺少以下依赖，请运行：" -ForegroundColor Yellow
    Write-Host "  pip install -r requirements.txt" -ForegroundColor White
}
Write-Host ""

# 3. 检查Node.js
Write-Host "[3/6] 检查Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    $nodeMajor = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
    if ($nodeMajor -ge 20) {
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Node.js版本过低: $nodeVersion" -ForegroundColor Red
        Write-Host "   需要Node.js 20.19.0+ 或 22.12.0+ 或 24.0.0+" -ForegroundColor Yellow
        $allOk = $false
    }
} catch {
    Write-Host "❌ Node.js未安装" -ForegroundColor Red
    Write-Host "   请从 https://nodejs.org/ 下载安装" -ForegroundColor Yellow
    $allOk = $false
}
Write-Host ""

# 4. 检查Appium
Write-Host "[4/6] 检查Appium..." -ForegroundColor Yellow
try {
    $appiumVersion = appium --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Appium: $appiumVersion" -ForegroundColor Green
        
        # 检查UiAutomator2驱动
        $drivers = appium driver list 2>&1
        if ($drivers -match "uiautomator2") {
            Write-Host "✅ UiAutomator2驱动: 已安装" -ForegroundColor Green
        } else {
            Write-Host "⚠️  UiAutomator2驱动: 未安装" -ForegroundColor Yellow
            Write-Host "   请运行: appium driver install uiautomator2" -ForegroundColor White
        }
    } else {
        Write-Host "❌ Appium未安装" -ForegroundColor Red
        Write-Host "   请运行: npm install -g appium" -ForegroundColor Yellow
        $allOk = $false
    }
} catch {
    Write-Host "❌ Appium未安装" -ForegroundColor Red
    Write-Host "   请运行: npm install -g appium" -ForegroundColor Yellow
    $allOk = $false
}
Write-Host ""

# 5. 检查ADB
Write-Host "[5/6] 检查ADB..." -ForegroundColor Yellow
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdk\platform-tools\adb.exe"

if (Test-Path $adb) {
    Write-Host "✅ ADB: $adb" -ForegroundColor Green
    try {
        $adbVersion = & $adb version 2>&1
        Write-Host "   $adbVersion" -ForegroundColor Gray
    } catch {
        Write-Host "⚠️  ADB路径存在但无法运行" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  ADB未找到（自动路径）" -ForegroundColor Yellow
    Write-Host "   路径: $adb" -ForegroundColor Gray
    Write-Host "   如果已安装Android Studio，脚本会自动查找" -ForegroundColor Gray
    Write-Host "   或手动设置ANDROID_HOME环境变量" -ForegroundColor Gray
}
Write-Host ""

# 6. 检查设备连接
Write-Host "[6/6] 检查设备连接..." -ForegroundColor Yellow
if (Test-Path $adb) {
    try {
        & $adb kill-server 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        & $adb start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        $devices = & $adb devices
        $deviceLines = $devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if ($deviceLines.Count -gt 0) {
            Write-Host "✅ 设备已连接" -ForegroundColor Green
            foreach ($line in $deviceLines) {
                $deviceId = ($line -split "\s+")[0]
                Write-Host "   设备: $deviceId" -ForegroundColor Gray
            }
        } else {
            Write-Host "⚠️  未检测到设备" -ForegroundColor Yellow
            Write-Host "   请参考: 使用指南\连接步骤.md" -ForegroundColor White
        }
    } catch {
        Write-Host "⚠️  无法检查设备（ADB可能有问题）" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  无法检查设备（ADB未找到）" -ForegroundColor Yellow
}
Write-Host ""

# 7. 检查配置文件
Write-Host "[7/6] 检查配置文件..." -ForegroundColor Yellow
if (Test-Path "config.yaml") {
    Write-Host "✅ 配置文件存在: config.yaml" -ForegroundColor Green
} elseif (Test-Path "config.example.yaml") {
    Write-Host "⚠️  配置文件不存在，但找到示例文件" -ForegroundColor Yellow
    Write-Host "   请复制 config.example.yaml 为 config.yaml 并配置" -ForegroundColor White
} else {
    Write-Host "❌ 配置文件不存在" -ForegroundColor Red
    Write-Host "   请创建 config.yaml 配置文件" -ForegroundColor Yellow
}
Write-Host ""

# 总结
Write-Host "========================================" -ForegroundColor Cyan
if ($allOk) {
    Write-Host "✅ 所有必需依赖已安装！" -ForegroundColor Green
    Write-Host ""
    Write-Host "可以开始使用框架了：" -ForegroundColor Cyan
    Write-Host "  1. 配置 config.yaml（参考 config.example.yaml）" -ForegroundColor White
    Write-Host "  2. 获取目标 App 的元素定位器" -ForegroundColor White
    Write-Host "  3. 连接设备（参考: 使用指南\连接步骤.md）" -ForegroundColor White
    Write-Host "  4. 运行: 启动脚本.bat 或 python smart_mobile_automation.py" -ForegroundColor White
} else {
    Write-Host "❌ 部分依赖缺失，请先安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "安装步骤：" -ForegroundColor Yellow
    Write-Host "  1. 参考: 使用指南\安装指南.md" -ForegroundColor White
    Write-Host "  2. 安装Python依赖: pip install -r requirements.txt" -ForegroundColor White
    Write-Host "  3. 安装Appium: npm install -g appium" -ForegroundColor White
}
Write-Host "========================================" -ForegroundColor Cyan

