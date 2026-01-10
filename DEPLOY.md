# 🚀 部署指南

## 快速部署到GitHub Pages

### 第一步：创建GitHub仓库

1. 登录GitHub账户
2. 点击右上角的"+"号，选择"New repository"
3. 仓库名设置为：`news-hub`（或你喜欢的名字）
4. 选择Public仓库
5. 勾选"Add a README file"
6. 点击"Create repository"

### 第二步：上传代码

#### 方法A：使用GitHub网页界面（推荐新手）

1. 在新创建的仓库中，点击"Add file" → "Upload files"
2. 将项目中的所有文件拖拽上传
3. 填写提交信息："Initial commit: News aggregation website"
4. 点击"Commit changes"

#### 方法B：使用Git命令行（推荐有经验的用户）

```bash
# 克隆你的仓库
git clone https://github.com/yourusername/news-hub.git
cd news-hub

# 复制项目文件到仓库目录
cp -r /path/to/project/* .

# 提交并推送
git add .
git commit -m "Initial commit: News aggregation website"
git push origin main
```

### 第三步：启用GitHub Pages

1. 在仓库页面，点击"Settings"标签
2. 在左侧菜单中找到"Pages"
3. 在"Build and deployment"部分：
   - Source: 选择"Deploy from a branch"
   - Branch: 选择"main"
   - Folder: 选择"/ (root)"
4. 点击"Save"

### 第四步：配置自动部署

1. 确保你的仓库中有`.github/workflows/deploy.yml`文件
2. GitHub Actions会自动运行，将网站部署到GitHub Pages
3. 等待几分钟，访问：`https://yourusername.github.io/news-hub`

## 🎯 自定义配置

### 修改网站信息

编辑`index.html`文件中的以下部分：

```html
<!-- 修改网站标题 -->
<title>你的网站名称</title>

<!-- 修改页眉 -->
<h1 class="text-xl font-bold text-gray-900">你的网站名称</h1>
```

### 修改更新频率

编辑`js/news-manager.js`文件：

```javascript
// 修改自动更新间隔（毫秒）
this.updateInterval = 60 * 60 * 1000; // 1小时

// 修改缓存过期时间（小时）
if (hoursDiff < 24) { // 24小时后过期
```

### 添加新平台

1. 在`js/news-manager.js`中添加新平台方法：

```javascript
async getNewPlatformNews() {
    // 添加获取新平台数据的代码
    return [];
}
```

2. 在HTML中添加新平台区域：

```html
<div class="bg-white rounded-lg shadow-md p-6">
    <div class="flex items-center mb-4">
        <i class="ri-new-icon-line text-2xl mr-2"></i>
        <h2 class="text-lg font-semibold">新平台热点</h2>
    </div>
    <div id="newplatformNews" class="space-y-3"></div>
</div>
```

## 🔧 高级配置

### 自定义域名

1. 在GitHub仓库的Settings → Pages中
2. 在"Custom domain"中输入你的域名
3. 在域名提供商处添加CNAME记录：
   - 主机记录：www
   - 记录值：yourusername.github.io

### 添加Google Analytics

1. 注册Google Analytics账户
2. 获取跟踪ID（如：G-XXXXXXXXXX）
3. 在`index.html`的`<head>`中添加：

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### 添加评论系统

使用Utterances或Gitalk添加评论功能：

```html
<!-- 在页面底部添加评论区域 -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div id="comments"></div>
</div>

<script src="https://utteranc.es/client.js"
        repo="yourusername/news-hub"
        issue-term="title"
        theme="github-light"
        crossorigin="anonymous"
        async>
</script>
```

## 📱 移动端优化

网站已经使用Tailwind CSS实现了响应式设计，但你可以进一步优化：

1. 在`index.html`中调整移动端显示
2. 优化触摸交互
3. 添加PWA支持

## 🔄 自动更新设置

GitHub Actions已经配置为每小时更新一次，你可以修改`.github/workflows/deploy.yml`：

```yaml
schedule:
  # 每小时更新一次
  - cron: '0 * * * *'
  
  # 或每6小时更新一次
  # - cron: '0 */6 * * *'
  
  # 或每天更新一次
  # - cron: '0 0 * * *'
```

## 🐛 故障排除

### 常见问题

1. **网站无法访问**
   - 检查GitHub Pages是否启用
   - 等待几分钟让部署完成
   - 检查仓库名称是否正确

2. **内容不更新**
   - 检查GitHub Actions是否正常运行
   - 查看Actions日志排查错误
   - 手动触发Actions运行

3. **样式显示异常**
   - 检查CDN链接是否可访问
   - 清除浏览器缓存
   - 检查控制台错误信息

### 获取帮助

- 查看GitHub Issues：`https://github.com/yourusername/news-hub/issues`
- 提交新Issue描述问题
- 联系项目维护者

## 📈 监控和分析

### 添加访问统计

使用Google Analytics或其他统计工具监控网站访问情况。

### 性能优化

1. 压缩图片资源
2. 优化JavaScript代码
3. 使用CDN加速
4. 启用Gzip压缩

---

🎉 **恭喜！你的新闻聚合网站已经部署完成！**

现在访问 `https://yourusername.github.io/news-hub` 查看你的网站吧！