# Next5h 官网与落地页 (Website & Landing Page)

本目录为 **Next5h** 的官方产品落地页与安装指引网站，完全自包含、零重型构建依赖，采用纯原生现代 HTML5、CSS3 与 Vanilla JavaScript 打造，遵循 Apple 原生及 Linear 设计美学。

---

## 目录结构

```
website/
├── index.html          # 官网主页 (语义化 HTML5、暗/亮色自适应、SEO 规范)
├── css/
│   ├── style.css       # 核心样式 (设计令牌、暗/亮色切换、毛玻璃、响应式排版)
│   └── components.css  # 专用组件 (安装选项卡、矩阵表格、FAQ手风琴)
├── js/
│   └── main.js         # 核心交互 (暗亮色切换、一键复制反馈、平滑滚动、移动端抽屉)
├── assets/
│   ├── icon.svg        # Next5h 原生矢量应用图标
│   └── favicon.svg     # 浏览器 Favicon
└── README.md           # 本文档
```

---

## 本地快速预览

官网为静态网页，无需编译即可直接运行。

### 方式一：直接用浏览器打开
双击 `website/index.html` 或在终端运行：
```bash
open website/index.html
```

### 方式二：使用 Python 简易 HTTP 服务
```bash
cd website
python3 -m http.server 8000
# 浏览器访问：http://localhost:8000
```

### 方式三：使用 Node.js / npx serve
```bash
npx serve website
```

---

## 部署上线

### 1. GitHub Pages
在仓库 Settings -> Pages 中：
* **Source**: Deploy from a branch
* **Branch**: `main`
* **Folder**: `/website`
点击保存即可自动发布。

### 2. Vercel
直接导入仓库，将 **Root Directory** 设置为 `website`，点击 Deploy 即可。

### 3. Cloudflare Pages
在 Cloudflare Dashboard 创建 Pages 项目，指定构建输出目录为 `website` 即可。
