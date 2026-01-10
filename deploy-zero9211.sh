#!/bin/bash

# 专门为用户 zero9211 的部署脚本
echo "🚀 为用户 zero9211 部署新闻聚合网站"
echo "=================================="
echo ""

# 检查当前目录
if [ ! -f "index.html" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

echo "📂 当前目录: $(pwd)"
echo "👤 用户名: zero9211"
echo "📁 仓库: zero9211/news-hub"
echo ""

# 设置Git用户信息
echo "⚙️ 配置Git用户信息..."
git config --global user.name "zero9211"
git config --global user.email "zero9211@users.noreply.github.com"

# 提交当前更改（如果有的话）
echo "📝 提交代码更改..."
git add .
git diff --cached --quiet
if [ $? -ne 0 ]; then
    git commit -m "Deploy news aggregation website - $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "📄 没有新的更改需要提交"
fi

echo ""
echo "🔑 推送到GitHub..."
echo "📋 当需要认证时："
echo "   用户名: zero9211"
echo "   密码: 你的Personal Access Token (PAT)"
echo "   📝 Token获取指南: 查看 GITHUB_TOKEN_GUIDE.md"
echo ""

# 尝试推送
git push -u origin main --force

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 代码推送成功！"
    echo ""
    echo "🌐 下一步：启用GitHub Pages"
    echo "1. 访问: https://github.com/zero9211/news-hub/settings/pages"
    echo "2. Source: 选择 'Deploy from a branch'"
    echo "3. Branch: 选择 'main'"
    echo "4. Folder: 选择 '/ (root)'"
    echo "5. 点击 'Save'"
    echo ""
    echo "⏱️ 部署需要2-5分钟"
    echo "🌐 网站地址: https://zero9211.github.io/news-hub"
else
    echo ""
    echo "❌ 推送失败，请检查认证信息"
    echo ""
    echo "🔧 解决方案："
    echo "1. 按照指南 GITHUB_TOKEN_GUIDE.md 创建Personal Access Token"
    echo "2. 重新运行此脚本"
    echo "3. 输入正确的Token作为密码"
    echo ""
    echo "📝 记住：GitHub不再支持密码认证，必须使用Token"
fi

echo ""
echo "📋 Token快速创建步骤："
echo "1. GitHub → Settings → Developer settings"
echo "2. Personal access tokens → Tokens (classic)"
echo "3. Generate new token → 勾选 repo 权限"
echo "4. 复制生成的Token"
echo ""