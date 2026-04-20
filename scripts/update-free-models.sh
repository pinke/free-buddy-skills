#!/bin/bash

# Free Buddy Skills - 自动更新 opencode.ai 免费模型配置
# 用法: ./update-free-models.sh

MODELS_FILE="$HOME/.workbuddy/models.json"
OPENCEND_URL="https://opencode.ai/zen/v1/models"

echo "🔍 正在查询 opencode.ai 免费模型..."

# 获取免费模型列表
FREE_MODELS=$(curl -sS "$OPENCEND_URL" | jq -r '.data[].id' | grep -i free)

if [ -z "$FREE_MODELS" ]; then
    echo "❌ 未找到免费模型或 API 不可用"
    exit 1
fi

echo "✅ 找到以下免费模型:"
echo "$FREE_MODELS"
echo ""

# 检查 models.json 是否存在
if [ ! -f "$MODELS_FILE" ]; then
    echo "⚠️  配置文件不存在: $MODELS_FILE"
    echo "请先创建配置文件"
    exit 1
fi

# 读取现有配置
echo "📋 现有配置中的免费模型:"
jq -r '.models[] | select(.id | contains("free")) | .id' "$MODELS_FILE" 2>/dev/null
echo ""

# 检查每个模型是否需要更新
NEEDS_UPDATE=false
for MODEL in $FREE_MODELS; do
    EXISTING=$(jq -r ".models[] | select(.id == \"$MODEL\") | .id" "$MODELS_FILE" 2>/dev/null)
    
    if [ -z "$EXISTING" ]; then
        echo "➕ 新模型: $MODEL (需要添加)"
        NEEDS_UPDATE=true
    else
        echo "✅ 已存在: $MODEL"
    fi
done

echo ""
if [ "$NEEDS_UPDATE" = true ]; then
    echo "💡 提示: 请使用 WorkBuddy 添加新模型到配置"
    echo "配置格式:"
    echo '{'
    echo '  "id": "'$MODEL'",'
    echo '  "name": "'$MODEL'",'
    echo '  "vendor": "OpenCode AI",'
    echo '  "url": "https://opencode.ai/zen/v1/chat/completions",'
    echo '  "apiKey": "public",'
    echo '  "maxInputTokens": 262144,'
    echo '  "supportsToolCall": true,'
    echo '  "supportsImages": false,'
    echo '  "supportsReasoning": true'
    echo '}'
else
    echo "✨ 所有模型配置已是最新"
fi
