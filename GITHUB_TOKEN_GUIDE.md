# 🔐 GitHub Personal Access Token (PAT) 设置指南

## 🚨 重要提醒

GitHub 已停止支持密码认证！现在需要使用 Personal Access Token 进行身份验证。

---

## 📋 创建 Personal Access Token

### 第1步：登录GitHub
1. 访问 https://github.com
2. 使用你的账户 `zero9211` 登录

### 第2步：进入设置页面
1. 点击右上角你的头像
2. 选择 "Settings"

### 第3步：创建新的Token
1. 在左侧菜单中找到 "Developer settings"
2. 点击 "Personal access tokens" → "Tokens (classic)"
3. 点击 "Generate new token" → "Generate new token (classic)"

### 第4步：配置Token
- **Note**: 输入描述，比如 "News Hub Deployment"
- **Expiration**: 选择 90 days 或 No expiration
- **Scopes**: 勾选以下权限：
  - ☑️ `repo` (完整仓库访问权限)
  - ☑️ `workflow` (GitHub Actions权限)
  - ☑️ `delete_repo` (删除仓库权限，可选)

### 第5步：生成并复制Token
1. 点击 "Generate token"
2. **立即复制生成的Token**（非常重要！它只显示一次）
3. 安全保存这个Token

---

## 🚀 使用Token部署网站

### 方法A：直接使用Token（推荐）

1. **重新运行部署脚本**：
```bash
cd /tmp/news-hub
./auto-deploy.sh
```

2. **当提示输入时**：
- GitHub用户名: `zero9211`
- GitHub邮箱: 你的邮箱地址
- GitHub访问token: 粘贴刚才复制的Token

### 方法B：配置Git使用Token

1. **设置Git凭据**：
```bash
git config --global credential.helper store
```

2. **推送时使用Token**：
- 用户名: `zero9211`
- 密码: 你的Personal Access Token

---

## 🔧 更新现有仓库的远程URL

如果仓库已存在但需要更新认证：

```bash
cd /tmp/news-hub
git remote remove origin
git remote add origin https://zero9211:YOUR_TOKEN@github.com/zero9211/news-hub.git
```

将 `YOUR_TOKEN` 替换为你的实际Token。

---

## 🛡️ Token安全注意事项

1. **不要在代码中硬编码Token**
2. **定期更换Token**
3. **使用最小权限原则**
4. **不要分享Token给他人**

---

## 🎯 快速部署步骤总结

1. **创建Personal Access Token** (按上述步骤)
2. **复制Token到剪贴板**
3. **运行部署脚本**：
   ```bash
   cd /tmp/news-hub
   ./auto-deploy.sh
   ```
4. **输入信息**：
   - 用户名: `zero9211`
   - 邮箱: 你的邮箱
   - Token: 粘贴刚才复制的Token

---

## 🆘 常见问题

### Q: Token创建后忘记复制了？
A: 删除旧的Token，重新创建一个新的。

### Q: 推送时仍然提示认证失败？
A: 确认Token有正确的权限（至少需要repo权限）

### Q: 如何检查Token是否有效？
A: 在GitHub Settings → Developer settings → Personal access tokens 中查看活跃的Token列表。

---

## 📞 需要更多帮助？

- GitHub官方文档: https://docs.github.com/en/authentication
- Token创建页面: https://github.com/settings/tokens

---

🔑 **准备好Token后，我们就可以继续部署了！**