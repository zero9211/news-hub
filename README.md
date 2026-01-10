# 🌍 全球热点新闻聚合网站

[![GitHub stars](https://img.shields.io/github/stars/yourusername/news-hub?style=social)](https://github.com/yourusername/news-hub/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yourusername/news-hub?style=social)](https://github.com/yourusername/news-hub/network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions](https://github.com/yourusername/news-hub/workflows/Deploy/badge.svg)](https://github.com/yourusername/news-hub/actions)

一个自动聚合全球各大平台热点新闻的网站，支持实时更新和双语显示。

## ✨ 功能特点

- 📰 **多平台聚合**: X(Twitter)、TikTok、微博、Reddit等平台热点
- 🌍 **双语显示**: 中英文标题对照显示
- ⚡ **实时更新**: 每小时自动更新最新热点
- 📱 **响应式设计**: 完美适配手机、平板、桌面设备
- 🎨 **现代界面**: 简洁美观的用户界面
- 🔄 **离线支持**: Service Worker缓存，支持离线浏览
- 🚀 **快速部署**: 一键部署到GitHub Pages

## 🚀 快速开始

### 方法一：直接部署（推荐）

1. **Fork 这个仓库**
   - 点击右上角的Fork按钮
   - 选择你的GitHub账户

2. **启用GitHub Pages**
   - 进入仓库Settings → Pages
   - Source选择"Deploy from a branch"
   - Branch选择"main"，文件夹选择"/(root)"
   - 点击Save

3. **访问网站**
   - 等待2-3分钟部署完成
   - 访问 `https://yourusername.github.io/news-hub`

### 方法二：本地开发

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/news-hub.git
cd news-hub
```

2. **启动本地服务器**
```bash
# 使用Python
python3 -m http.server 8000

# 或使用Node.js
npx serve .

# 或使用PHP
php -S localhost:8000
```

3. **访问网站**
```
http://localhost:8000
```

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| **HTML5** | 页面结构 |
| **Tailwind CSS** | 样式框架 |
| **JavaScript (ES6+)** | 交互逻辑 |
| **GitHub Pages** | 静态托管 |
| **GitHub Actions** | 自动部署 |
| **Service Worker** | 离线支持 |

## 📊 项目结构

```
news-hub/
├── index.html              # 主页面
├── about.html              # 关于页面
├── js/
│   ├── news-manager.js     # 新闻管理器
│   └── real-api.js         # 真实API集成（可选）
├── sw.js                   # Service Worker
├── .github/workflows/
│   └── deploy.yml          # 自动部署配置
├── README.md               # 项目说明
├── DEPLOY.md               # 部署指南
└── LICENSE                 # 开源协议
```

## ⚙️ 配置说明

### 修改更新频率

编辑 `js/news-manager.js`：

```javascript
// 修改自动更新间隔（毫秒）
this.updateInterval = 60 * 60 * 1000; // 1小时

// 修改缓存过期时间（小时）
if (hoursDiff < 24) { // 24小时后过期
```

### 添加新平台

1. 在 `js/news-manager.js` 中添加新平台方法
2. 在 `index.html` 中添加对应的显示区域
3. 更新样式和图标

### 自定义样式

网站使用Tailwind CSS，你可以：
- 修改 `index.html` 中的类名
- 添加自定义CSS到 `<style>` 标签
- 使用Tailwind配置文件进行深度定制

## 🔌 API集成

### 模拟数据（默认）

网站默认使用模拟数据，无需API密钥即可运行。

### 真实API集成

如需使用真实API，请参考 `js/real-api.js`：

1. **获取API密钥**
   - Twitter API: https://developer.twitter.com/
   - Reddit API: https://www.reddit.com/dev/api/
   - 其他平台API

2. **配置环境变量**
   ```yaml
   # 在GitHub Actions中配置
   env:
     TWITTER_API_KEY: ${{ secrets.TWITTER_API_KEY }}
     REDDIT_API_KEY: ${{ secrets.REDDIT_API_KEY }}
   ```

3. **修改代码使用真实API**

## 📱 移动端优化

- 响应式布局，适配各种屏幕尺寸
- 触摸友好的交互设计
- 快速加载和流畅滚动
- PWA支持（可添加到主屏幕）

## 🔄 自动更新

网站通过GitHub Actions自动更新：

```yaml
schedule:
  # 每小时更新一次
  - cron: '0 * * * *'
```

你可以修改 `.github/workflows/deploy.yml` 中的cron表达式来调整更新频率。

## 📈 性能优化

- 使用CDN加载外部资源
- 图片懒加载
- Service Worker缓存
- 代码压缩和优化

## 🐛 故障排除

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| 网站无法访问 | 检查GitHub Pages设置，等待部署完成 |
| 样式显示异常 | 清除浏览器缓存，检查CDN链接 |
| 内容不更新 | 检查GitHub Actions运行状态 |
| 移动端显示问题 | 检查响应式CSS配置 |

### 获取帮助

- 📋 [提交Issue](https://github.com/yourusername/news-hub/issues)
- 💬 [GitHub Discussions](https://github.com/yourusername/news-hub/discussions)
- 📧 邮件联系：your.email@example.com

## 🤝 贡献指南

欢迎为项目做出贡献！

### 贡献方式

1. **报告Bug**: 在Issues中描述问题
2. **功能建议**: 提出新功能想法
3. **代码贡献**: 提交Pull Request
4. **文档改进**: 完善项目文档

### 开发流程

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

### 代码规范

- 使用ES6+语法
- 遵循驼峰命名法
- 添加适当的注释
- 保持代码简洁清晰

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢以下开源项目和服务：

- [Tailwind CSS](https://tailwindcss.com/) - CSS框架
- [Remix Icon](https://remixicon.com/) - 图标库
- [GitHub Pages](https://pages.github.com/) - 静态托管
- [GitHub Actions](https://github.com/features/actions) - CI/CD

## 📊 项目统计

![GitHub stars](https://img.shields.io/github/stars/yourusername/news-hub?style=social)
![GitHub forks](https://img.shields.io/github/forks/yourusername/news-hub?style=social)
![GitHub issues](https://img.shields.io/github/issues/yourusername/news-hub)
![GitHub pull requests](https://img.shields.io/github/issues-pr/yourusername/news-hub)

---

⭐ **如果这个项目对你有帮助，请给个Star支持一下！**

📧 **联系我**: [your.email@example.com](mailto:your.email@example.com)

🌐 **项目主页**: [https://yourusername.github.io/news-hub](https://yourusername.github.io/news-hub)