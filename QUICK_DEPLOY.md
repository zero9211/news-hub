# 🚀 快速部署到GitHub Pages - 分步指南

## 📋 准备工作

确保你有一个GitHub账户。如果没有，请先注册：
👉 https://github.com/signup

---

## 🎯 部署步骤（5分钟完成）

### 第1步：下载项目文件

由于我们在本地创建了项目，你需要先获取项目文件。以下是几种方法：

#### 方法A：复制代码（推荐新手）
1. 创建一个新文件夹，比如 `news-hub`
2. 复制下面的每个文件内容到对应文件

#### 方法B：使用生成的项目
1. 找到我们创建的项目文件（在 `/tmp/news-hub`）
2. 复制整个文件夹到你的工作目录

### 第2步：创建GitHub仓库

1. **登录GitHub**
   - 访问 https://github.com
   - 使用你的账户登录

2. **创建新仓库**
   - 点击右上角的 "+" → "New repository"
   - 填写仓库信息：
     ```
     Repository name: news-hub
     Description: 全球热点新闻聚合网站
     Visibility: ☑️ Public
     ☑️ Add a README file
     ```
   - 点击 "Create repository"

### 第3步：上传项目文件

#### 使用网页界面上传（最简单）

1. 在新创建的仓库页面，点击 "Add file" → "Upload files"

2. 上传以下文件（按顺序）：
   ```
   index.html
   about.html
   js/news-manager.js
   js/real-api.js
   sw.js
   .github/workflows/deploy.yml
   README.md
   LICENSE
   ```

3. 对于每个文件：
   - 点击"Add file"
   - 选择"Upload files"
   - 拖拽或选择文件
   - 在下方的文本框中粘贴文件内容
   - 给文件命名
   - 点击"Commit changes"

#### 使用Git命令行上传（推荐有经验的用户）

```bash
# 克隆你的仓库
git clone https://github.com/你的用户名/news-hub.git
cd news-hub

# 复制项目文件到此目录

# 提交并推送
git add .
git commit -m "Add news aggregation website"
git push origin main
```

### 第4步：启用GitHub Pages

1. **进入仓库设置**
   - 在仓库页面，点击 "Settings" 标签
   - 在左侧菜单中找到 "Pages"

2. **配置Pages**
   - Source: 选择 "Deploy from a branch"
   - Branch: 选择 "main"
   - Folder: 选择 "/ (root)"
   - 点击 "Save"

3. **等待部署**
   - GitHub会自动构建和部署网站
   - 通常需要2-5分钟完成

---

## ✅ 验证部署

### 检查部署状态

1. **查看Pages状态**
   - 在 Settings → Pages 页面查看状态
   - 状态显示 "Your site is published" 表示成功

2. **访问网站**
   - 网站地址：`https://你的用户名.github.io/news-hub`
   - 如果不工作，等待几分钟后刷新

### 预期效果

你应该看到：
- 📰 四个平台的热点新闻卡片
- 🌍 中英文双语显示
- 📱 响应式布局
- 🔄 自动刷新按钮
- ⏰ 更新时间显示

---

## 🔧 配置自动更新

### 启用GitHub Actions

1. **进入Actions设置**
   - Settings → Actions → General
   - 找到 "Workflow permissions"
   - 选择：
     ```
     ☑️ Allow all actions and reusable workflows
     ☑️ Read and write permissions
     ☑️ Allow GitHub Actions to create and approve pull requests
     ```

2. **保存设置**
   - 点击 "Save"

### 验证自动更新

1. **查看Actions运行**
   - 点击 "Actions" 标签
   - 应该看到 "Deploy" workflow在运行
   - 如果失败，查看日志解决

2. **定时更新**
   - 网站每小时自动更新一次
   - 也可手动点击页面上的"刷新"按钮

---

## 🎉 完成！

恭喜！你已经成功部署了新闻聚合网站！

### 📱 享受你的网站

- **网站地址**: `https://你的用户名.github.io/news-hub`
- **功能**: 实时聚合X、TikTok、微博、Reddit热点
- **更新**: 每小时自动获取最新内容

### 🔧 自定义你的网站

- 修改 `index.html` 更改网站标题和内容
- 编辑 `js/news-manager.js` 调整更新频率
- 在 `about.html` 中添加你的个人信息

### 📈 下一步

1. **分享你的网站** - 告诉朋友你的新闻聚合网站
2. **添加自定义功能** - 比如搜索、筛选等
3. **集成真实API** - 使用真实的平台API获取数据
4. **添加分析统计** - 使用Google Analytics跟踪访问

---

## 🆘 常见问题

### Q: 网站无法访问？
A: 等待3-5分钟让部署完成，或者检查Pages设置

### Q: 样式显示异常？
A: 清除浏览器缓存，检查网络连接

### Q: 内容不更新？
A: 检查GitHub Actions是否正常运行

### Q: 移动端显示问题？
A: 网站已经优化了响应式设计，应该是正常的

---

## 📞 需要帮助？

如果遇到问题：
1. 查看 [GitHub Pages文档](https://docs.github.com/en/pages)
2. 检查项目的 [Issues页面](https://github.com/你的用户名/news-hub/issues)
3. 参考上面的故障排除指南

---

🎊 **太棒了！你现在拥有一个功能完整的新闻聚合网站了！**

🌐 **立即访问**: `https://你的用户名.github.io/news-hub`