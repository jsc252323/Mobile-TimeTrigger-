# Git 上传脚本
# 使用 PowerShell 执行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  上传项目到 GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 设置错误处理
$ErrorActionPreference = "Stop"

try {
    # 1. 检查是否已初始化
    if (-not (Test-Path ".git")) {
        Write-Host "[1/6] 初始化 Git 仓库..." -ForegroundColor Yellow
        git init
        Write-Host "✅ Git 仓库初始化成功" -ForegroundColor Green
    } else {
        Write-Host "[1/6] Git 仓库已存在" -ForegroundColor Green
    }
    Write-Host ""

    # 2. 配置用户信息（如果需要）
    Write-Host "[2/6] 检查 Git 配置..." -ForegroundColor Yellow
    $gitUser = git config user.name
    $gitEmail = git config user.email
    
    if (-not $gitUser) {
        Write-Host "⚠️  未配置 Git 用户信息" -ForegroundColor Yellow
        Write-Host "   请运行以下命令配置（可选）：" -ForegroundColor Gray
        Write-Host "   git config --global user.name 'Your Name'" -ForegroundColor Gray
        Write-Host "   git config --global user.email 'your.email@example.com'" -ForegroundColor Gray
    } else {
        Write-Host "✅ Git 用户: $gitUser ($gitEmail)" -ForegroundColor Green
    }
    Write-Host ""

    # 3. 添加远程仓库
    Write-Host "[3/6] 配置远程仓库..." -ForegroundColor Yellow
    $remoteExists = git remote get-url origin 2>$null
    if ($remoteExists) {
        Write-Host "✅ 远程仓库已配置: $remoteExists" -ForegroundColor Green
        git remote set-url origin https://github.com/jsc252323/Mobile-TimeTrigger-.git
    } else {
        git remote add origin https://github.com/jsc252323/Mobile-TimeTrigger-.git
        Write-Host "✅ 远程仓库配置成功" -ForegroundColor Green
    }
    Write-Host ""

    # 4. 添加所有文件
    Write-Host "[4/6] 添加文件到暂存区..." -ForegroundColor Yellow
    git add .
    Write-Host "✅ 文件已添加到暂存区" -ForegroundColor Green
    Write-Host ""

    # 5. 提交更改
    Write-Host "[5/6] 提交更改..." -ForegroundColor Yellow
    $commitMessage = "Initial commit: SmartMobileAutomation - 通用 Android App UI 自动化框架"
    
    # 检查是否有更改需要提交
    $status = git status --porcelain
    if ($status) {
        git commit -m $commitMessage
        Write-Host "✅ 提交成功" -ForegroundColor Green
    } else {
        Write-Host "⚠️  没有更改需要提交" -ForegroundColor Yellow
    }
    Write-Host ""

    # 6. 设置分支并推送
    Write-Host "[6/6] 设置分支并推送到 GitHub..." -ForegroundColor Yellow
    git branch -M main 2>$null
    
    Write-Host ""
    Write-Host "正在推送到 GitHub..." -ForegroundColor Cyan
    Write-Host "注意: 如果提示输入用户名和密码：" -ForegroundColor Yellow
    Write-Host "  - 用户名: 你的 GitHub 用户名" -ForegroundColor Gray
    Write-Host "  - 密码: 使用 Personal Access Token（不是账户密码）" -ForegroundColor Gray
    Write-Host "  - 生成 Token: https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host ""
    
    # 尝试推送
    git push -u origin main
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ 上传成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "项目地址: https://github.com/jsc252323/Mobile-TimeTrigger-" -ForegroundColor Cyan
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ 操作失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    
    # 提供故障排除建议
    Write-Host "可能的解决方案：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 认证问题：" -ForegroundColor Cyan
    Write-Host "   - GitHub 已不再支持密码认证" -ForegroundColor Gray
    Write-Host "   - 需要生成 Personal Access Token" -ForegroundColor Gray
    Write-Host "   - 访问: https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host "   - 生成 Token 时勾选 'repo' 权限" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 仓库已有内容：" -ForegroundColor Cyan
    Write-Host "   先拉取: git pull origin main --allow-unrelated-histories" -ForegroundColor Gray
    Write-Host "   然后再次推送" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 使用 SSH（推荐）：" -ForegroundColor Cyan
    Write-Host "   git remote set-url origin git@github.com:jsc252323/Mobile-TimeTrigger-.git" -ForegroundColor Gray
    Write-Host ""
    
    exit 1
}

