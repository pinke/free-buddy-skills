@echo off
REM Free Buddy Skills - 自动更新 opencode.ai 免费模型配置 (Windows 版本)
REM 用法: update-free-models.bat

setlocal enabledelayedexpansion

set "MODELS_FILE=%USERPROFILE%\.workbuddy\models.json"
set "OPencode_URL=https://opencode.ai/zen/v1/models"

echo.
echo 🔍 正在查询 opencode.ai 免费模型...
echo.

REM 检查 jq 是否可用 (Windows 需要安装 jq 或使用 PowerShell)
where jq >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  未找到 jq 命令
    echo.
    echo 请使用 PowerShell 方式运行:
    echo powershell -File update-free-models.ps1
    echo.
    echo 或者安装 jq:
    echo   - Scoop: scoop install jq
    echo   - Chocolatey: choco install jq
    echo.
    goto :end
)

REM 获取免费模型列表
for /f "delims=" %%i in ('curl -sS "%OPencode_URL%" ^| jq -r ".data[].id" ^| findstr /i "free"') do (
    set "FREE_MODELS=!FREE_MODELS! %%i"
)

if "!FREE_MODELS!" == "" (
    echo ❌ 未找到免费模型或 API 不可用
    goto :end
)

echo ✅ 找到以下免费模型:
echo !FREE_MODELS!
echo.

REM 检查 models.json 是否存在
if not exist "%MODELS_FILE%" (
    echo ⚠️  配置文件不存在: %MODELS_FILE%
    echo 请先创建配置文件
    goto :end
)

REM 读取现有配置
echo 📋 现有配置中的免费模型:
jq -r '.models[] ^| select(.id ^| contains("free")) ^| .id' "%MODELS_FILE%" 2>nul
echo.

REM 检查每个模型是否需要更新
set "NEEDS_UPDATE=false"
for %%M in (!FREE_MODELS!) do (
    set "MODEL=%%M"
    for /f "delims=" %%E in ('jq -r ".models[] ^| select(.id == \"!MODEL!\") ^| .id" "%MODELS_FILE%" 2^>nul') do (
        set "EXISTING=%%E"
    )
    
    if "!EXISTING!" == "" (
        echo ➕ 新模型: !MODEL! (需要添加)
        set "NEEDS_UPDATE=true"
    ) else (
        echo ✅ 已存在: !MODEL!
    )
)

echo.
if "!NEEDS_UPDATE!" == "true" (
    echo 💡 提示: 请使用 WorkBuddy 添加新模型到配置
    echo 配置格式:
    echo {
    echo   "id": "!MODEL!",
    echo   "name": "!MODEL!",
    echo   "vendor": "OpenCode AI",
    echo   "url": "https://opencode.ai/zen/v1/chat/completions",
    echo   "apiKey": "public",
    echo   "maxInputTokens": 262144,
    echo   "supportsToolCall": true,
    echo   "supportsImages": false,
    echo   "supportsReasoning": true
    echo }
) else (
    echo ✨ 所有模型配置已是最新
)

:end
echo.
pause
