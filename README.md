# 全球热点新闻聚合网站

一个自动聚合各大平台热点新闻的网站，每小时自动更新。

## 功能特点

- 📰 **多平台聚合**: X(Twitter)、TikTok、微博、Reddit等平台热点
- 🌍 **双语显示**: 中英文标题对照显示
- ⚡ **实时更新**: 每小时自动更新最新热点
- 📱 **响应式设计**: 支持手机、平板、桌面设备
- 🎨 **现代界面**: 简洁美观的用户界面

## 技术栈

- **前端**: HTML5 + Tailwind CSS + JavaScript
- **部署**: GitHub Pages
- **自动化**: GitHub Actions

## 本地开发

1. 克隆仓库
```bash
git clone https://github.com/yourusername/news-hub.git
cd news-hub
```

2. 启动本地服务器
```bash
# 使用Python
python -m http.server 8000

# 或使用Node.js
npx serve .

# 或使用PHP
php -S localhost:8000
```

3. 访问 `http://localhost:8000`

## 部署说明

1. Fork 这个仓库
2. 在仓库设置中启用 GitHub Pages
3. 选择源为 `gh-pages` 分支
4. 网站将自动部署到 `https://yourusername.github.io/news-hub/`

## 自动更新

网站通过 GitHub Actions 每小时自动更新：
- 获取各平台最新热点数据
- 更新网站内容
- 自动部署到 GitHub Pages

## 数据来源

- **X (Twitter)**: 通过API获取热门话题
- **TikTok**: 获取热门视频和挑战
- **微博**: 获取热搜榜和热门话题
- **Reddit**: 获取各subreddit热门帖子

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- Email: your.email@example.com

---

⭐ 如果这个项目对你有帮助，请给个 Star！