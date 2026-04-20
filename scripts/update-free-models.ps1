# Free Buddy Skills - 自动更新 opencode.ai 免费模型配置 (PowerShell 版本)
# 用法: powershell -ExecutionPolicy Bypass -File update-free-models.ps1

$ErrorActionPreference = "Stop"

$ModelsFile = Join-Path $env:USERPROFILE ".workbuddy\models.json"
$OpenCodeUrl = "https://opencode.ai/zen/v1/models"

Write-Host "`n🔍 正在查询 opencode.ai 免费模型..." -ForegroundColor Cyan
Write-Host ""

try {
    # 获取免费模型列表
    $ModelsJson = Invoke-RestMethod -Uri $OpenCodeUrl -Method Get
    $FreeModels = $ModelsJson.data | Where-Object { $_.id -like "*free*" } | Select-Object -ExpandProperty id
    
    if (-not $FreeModels) {
        Write-Host "❌ 未找到免费模型或 API 不可用" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ 找到以下免费模型:" -ForegroundColor Green
    $FreeModels | ForEach-Object { Write-Host "   - $_" }
    Write-Host ""
    
    # 检查 models.json 是否存在
    if (-not (Test-Path $ModelsFile)) {
        Write-Host "⚠️  配置文件不存在: $ModelsFile" -ForegroundColor Yellow
        Write-Host "请先创建配置文件" -ForegroundColor Yellow
        exit 1
    }
    
    # 读取现有配置
    $ExistingConfig = Get-Content $ModelsFile -Raw | ConvertFrom-Json
    Write-Host "📋 现有配置中的免费模型:" -ForegroundColor Cyan
    $ExistingConfig.models | Where-Object { $_.id -like "*free*" } | ForEach-Object {
        Write-Host "   - $($_.id)"
    }
    Write-Host ""
    
    # 检查每个模型是否需要更新
    $NeedsUpdate = $false
    foreach ($Model in $FreeModels) {
        $Existing = $ExistingConfig.models | Where-Object { $_.id -eq $Model }
        
        if (-not $Existing) {
            Write-Host "➕ 新模型: $Model (需要添加)" -ForegroundColor Yellow
            $NeedsUpdate = $true
        } else {
            Write-Host "✅ 已存在: $Model" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    if ($NeedsUpdate) {
        Write-Host "💡 提示: 请使用 WorkBuddy 添加新模型到配置" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "配置格式:" -ForegroundColor Cyan
        Write-Host @"
{
  "id": "$FreeModels[-1]",
  "name": "$FreeModels[-1]",
  "vendor": "OpenCode AI",
  "url": "https://opencode.ai/zen/v1/chat/completions",
  "apiKey": "public",
  "maxInputTokens": 262144,
  "supportsToolCall": true,
  "supportsImages": false,
  "supportsReasoning": true
}
"@
    } else {
        Write-Host "✨ 所有模型配置已是最新" -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ 错误: $_" -ForegroundColor Red
    Write-Host "详情: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "按任意键继续..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
