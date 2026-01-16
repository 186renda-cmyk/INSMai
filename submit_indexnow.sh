#!/bin/bash

# 配置信息
HOST="ins-mai.top"
KEY="a1b40e73f54b4eef97a6002663f8e89a"
KEY_LOCATION="https://${HOST}/${KEY}.txt"
SITEMAP_FILE="sitemap.xml"
INDEXNOW_ENDPOINT="https://api.indexnow.org/indexnow"

echo "开始 IndexNow 自动化提交..."

# 检查 sitemap.xml 是否存在
if [ ! -f "$SITEMAP_FILE" ]; then
    echo "❌ 错误: 找不到 $SITEMAP_FILE"
    exit 1
fi

# 提取 URL (简单的 grep/sed 提取，假设 sitemap 格式标准)
# 这里的逻辑是提取 <loc> 标签内的内容
URLS=$(grep -o '<loc>[^<]*</loc>' "$SITEMAP_FILE" | sed 's/<loc>//g; s/<\/loc>//g')

if [ -z "$URLS" ]; then
    echo "❌ 错误: 未能从 $SITEMAP_FILE 中提取到 URL"
    exit 1
fi

# 构造 JSON 数组
# "url1", "url2", "url3"
JSON_URL_LIST=""
FIRST=true
COUNT=0

# 设置 IFS 为换行符来处理 URL 列表
IFS=$'\n'
for url in $URLS; do
    # 去除可能的空白字符
    url=$(echo "$url" | xargs)
    if [ -n "$url" ]; then
        if [ "$FIRST" = true ]; then
            JSON_URL_LIST="\"$url\""
            FIRST=false
        else
            JSON_URL_LIST="$JSON_URL_LIST, \"$url\""
        fi
        ((COUNT++))
    fi
done
unset IFS

echo "提取到 $COUNT 个 URL，准备提交..."

# 构造完整的 JSON Payload
JSON_PAYLOAD=$(cat <<EOF
{
  "host": "$HOST",
  "key": "$KEY",
  "keyLocation": "$KEY_LOCATION",
  "urlList": [$JSON_URL_LIST]
}
EOF
)

# 发送请求
echo "正在发送请求到 IndexNow..."
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$INDEXNOW_ENDPOINT" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "$JSON_PAYLOAD")

# 提取状态码和响应体
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS")

if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 202 ]; then
    echo "✅ 提交成功！(HTTP $HTTP_STATUS)"
else
    echo "❌ 提交失败 (HTTP $HTTP_STATUS)"
    echo "响应内容: $BODY"
fi
