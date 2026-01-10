#!/bin/bash

# 自动部署脚本 - 一键部署到GitHub Pages
echo "🚀 GitHub Pages 一键部署脚本"
echo "=================================="
echo ""

# 检查是否安装了必要的工具
check_tools() {
    echo "🔧 检查必要工具..."
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        echo "❌ Git 未安装，请先安装Git"
        exit 1
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        echo "❌ curl 未安装，请先安装curl"
        exit 1
    fi
    
    echo "✅ 工具检查完成"
}

# 获取用户输入
get_user_input() {
    echo ""
    echo "📋 请输入以下信息："
    
    read -p "👤 GitHub用户名: " GITHUB_USER
    read -p "📧 GitHub邮箱: " GITHUB_EMAIL
    read -p "🔑 GitHub访问token (可选，按Enter跳过): " GITHUB_TOKEN
    
    if [ -z "$GITHUB_USER" ]; then
        echo "❌ 用户名不能为空"
        exit 1
    fi
    
    echo ""
    echo "✅ 信息获取完成"
}

# 配置Git
setup_git() {
    echo ""
    echo "⚙️ 配置Git..."
    
    git config --global user.name "$GITHUB_USER"
    git config --global user.email "$GITHUB_EMAIL"
    
    echo "✅ Git配置完成"
}

# 创建GitHub仓库
create_repo() {
    echo ""
    echo "📁 创建GitHub仓库..."
    
    REPO_NAME="news-hub"
    FULL_REPO_NAME="$GITHUB_USER/$REPO_NAME"
    
    # 检查仓库是否存在
    if curl -s "https://api.github.com/repos/$FULL_REPO_NAME" | grep -q "Not Found"; then
        echo "🆕 创建新仓库: $FULL_REPO_NAME"
        
        # 创建仓库的API请求
        curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/user/repos \
            -d "{\"name\":\"$REPO_NAME\",\"description\":\"全球热点新闻聚合网站\",\"private\":false}" \
            > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ 仓库创建成功"
        else
            echo "⚠️ 自动创建失败，请手动创建仓库"
            echo "📂 仓库地址: https://github.com/new"
            echo "💻 仓库名称: $REPO_NAME"
            echo "📝 描述: 全球热点新闻聚合网站"
            echo "🔓 可见性: Public"
        fi
    else
        echo "✅ 仓库已存在"
    fi
}

# 设置远程仓库
setup_remote() {
    echo ""
    echo "🔗 设置远程仓库..."
    
    # 移除现有的origin（如果有）
    git remote remove origin 2>/dev/null
    
    # 添加新的远程仓库
    git remote add origin "https://github.com/$FULL_REPO_NAME.git"
    
    echo "✅ 远程仓库设置完成"
}

# 推送代码
push_code() {
    echo ""
    echo "📤 推送代码到GitHub..."
    
    # 确保在main分支
    git checkout main 2>/dev/null || git checkout -b main
    
    # 添加所有文件
    git add .
    
    # 提交（如果还没有提交）
    if git diff --cached --quiet && git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "📝 没有新的更改需要提交"
    else
        git commit -m "Deploy news aggregation website - $(date)"
    fi
    
    # 推送
    git push -u origin main --force
    
    if [ $? -eq 0 ]; then
        echo "✅ 代码推送成功"
    else
        echo "❌ 代码推送失败，请检查凭据"
        echo "💡 你可能需要设置GitHub访问token"
        return 1
    fi
}

# 启用GitHub Pages
setup_pages() {
    echo ""
    echo "🌐 配置GitHub Pages..."
    
    echo "⏳ 等待仓库初始化..."
    sleep 5
    
    echo "📋 请手动启用GitHub Pages："
    echo "1. 访问: https://github.com/$FULL_REPO_NAME/settings/pages"
    echo "2. Source: 选择 'Deploy from a branch'"
    echo "3. Branch: 选择 'main'"
    echo "4. Folder: 选择 '/ (root)'"
    echo "5. 点击 'Save'"
    
    echo ""
    echo "⏱️ 部署需要2-5分钟时间"
}

# 显示结果
show_result() {
    echo ""
    echo "🎉 部署完成！"
    echo "=================="
    echo ""
    echo "📊 部署信息："
    echo "  📍 仓库地址: https://github.com/$FULL_REPO_NAME"
    echo "  🌐 网站地址: https://$GITHUB_USER.github.io/$REPO_NAME"
    echo "  ⏱️ 部署时间: 约2-5分钟"
    echo ""
    echo "📋 下一步操作："
    echo "1. 按照上述说明启用GitHub Pages"
    echo "2. 等待部署完成"
    echo "3. 访问你的网站"
    echo ""
    echo "🔧 网站功能："
    echo "  📰 X(Twitter)热点新闻"
    echo "  🎵 TikTok热门内容"
    echo "  📱 微博热搜榜"
    echo "  💬 Reddit热门帖子"
    echo "  🔄 每小时自动更新"
    echo ""
    echo "🌟 享受你的新闻聚合网站吧！"
}

# 主函数
main() {
    echo "🎯 开始部署新闻聚合网站到GitHub Pages..."
    echo ""
    
    # 检查是否在正确的目录
    if [ ! -f "index.html" ] || [ ! -f "js/news-manager.js" ]; then
        echo "❌ 请在项目根目录运行此脚本"
        echo "📂 当前目录应包含 index.html 和 js/news-manager.js"
        exit 1
    fi
    
    # 执行部署步骤
    check_tools
    get_user_input
    setup_git
    create_repo
    setup_remote
    push_code
    setup_pages
    show_result
}

# 运行主函数
main "$@"