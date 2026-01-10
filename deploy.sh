#!/bin/bash

# GitHub Pages部署脚本
# 使用前请确保已配置GitHub CLI并登录

echo "🚀 开始部署新闻聚合网站到GitHub Pages..."
echo ""

# 检查GitHub CLI是否安装
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) 未安装"
    echo "请先安装GitHub CLI:"
    echo "  macOS: brew install gh"
    echo "  Ubuntu: sudo apt install gh"
    echo "  Windows: winget install GitHub.cli"
    echo ""
    echo "然后运行: gh auth login"
    exit 1
fi

# 检查是否已登录GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ 未登录GitHub"
    echo "请先运行: gh auth login"
    exit 1
fi

# 获取GitHub用户名
GITHUB_USER=$(gh api user --jq '.login')
echo "👤 GitHub用户名: $GITHUB_USER"

# 仓库名称
REPO_NAME="news-hub"
FULL_REPO_NAME="$GITHUB_USER/$REPO_NAME"

echo ""
echo "📁 创建仓库: $FULL_REPO_NAME"

# 检查仓库是否已存在
if gh repo view "$FULL_REPO_NAME" &> /dev/null; then
    echo "✅ 仓库已存在"
else
    echo "🆕 创建新仓库..."
    gh repo create "$REPO_NAME" --public --clone=false --description="全球热点新闻聚合网站 - 实时更新X、TikTok、微博、Reddit等平台热点"
fi

# 获取当前目录
CURRENT_DIR=$(pwd)
PROJECT_DIR="$CURRENT_DIR"

echo ""
echo "📂 项目目录: $PROJECT_DIR"

# 添加远程仓库（如果尚未添加）
git remote get-url origin &> /dev/null
if [ $? -ne 0 ]; then
    echo "🔗 添加远程仓库..."
    git remote add origin "https://github.com/$FULL_REPO_NAME.git"
fi

# 推送到GitHub
echo ""
echo "📤 推送代码到GitHub..."
git push -u origin main --force

# 等待仓库初始化
echo ""
echo "⏳ 等待仓库初始化..."
sleep 5

# 启用GitHub Pages
echo ""
echo "🌐 启用GitHub Pages..."
gh api repos/"$FULL_REPO_NAME"/pages -X POST -f source[branch]=main -f source[path]/ '' --jq '.url' 2>/dev/null || echo "Pages已在配置中..."

echo ""
echo "📋 部署信息:"
echo "  📍 仓库地址: https://github.com/$FULL_REPO_NAME"
echo "  🌐 网站地址: https://$GITHUB_USER.github.io/$REPO_NAME"
echo "  ⏱️  部署时间: 约2-3分钟"

echo ""
echo "🔄 检查部署状态..."
sleep 10

# 检查Pages状态
PAGES_STATUS=$(gh api repos/"$FULL_REPO_NAME"/pages --jq '.status' 2>/dev/null || echo "构建中")
echo "📊 Pages状态: $PAGES_STATUS"

if [ "$PAGES_STATUS" = "built" ]; then
    echo "✅ 部署完成！"
    echo "🌐 访问网站: https://$GITHUB_USER.github.io/$REPO_NAME"
else
    echo "⏳ 部署进行中，请稍后访问..."
    echo "🌐 网站地址: https://$GITHUB_USER.github.io/$REPO_NAME"
    echo "📊 查看状态: https://github.com/$FULL_REPO_NAME/settings/pages"
fi

echo ""
echo "🎉 部署脚本执行完成！"
echo ""
echo "📌 后续操作:"
echo "1. 访问你的网站: https://$GITHUB_USER.github.io/$REPO_NAME"
echo "2. 确认网站正常工作"
echo "3. 在GitHub仓库中设置GitHub Actions权限"
echo "4. 享受你的新闻聚合网站吧！"