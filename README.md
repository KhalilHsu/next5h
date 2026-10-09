# Next5h website

Static product and installation site for [Next5h](https://khalilhsu.github.io/next5h/), maintained on the `gh-pages` branch. The application and its bilingual README live on `main`.

## Files

- `index.html`: product page, installation commands, compatibility conditions and FAQ.
- `css/style.css`: responsive layout and light/dark themes.
- `js/i18n.js`: Chinese/English copy and language selection.
- `js/main.js`: theme, language, illustrative demos, copying and latest-release links.
- `assets/`: icons and the actual app screenshot, supplied October 9, 2026.

## Preview and publish

```bash
python3 -m http.server 8000
# Open http://localhost:8000
```

GitHub Pages publishes the root of `gh-pages`. Push this branch to update the site. Screenshots and feature descriptions follow current `main`; download links resolve to the latest published release, which may lag behind source.

---

## 简体中文

官网为纯静态 HTML / CSS / JavaScript，支持中英切换、亮暗主题和响应式布局。网站源码维护在 **`gh-pages` 分支根目录**，应用与双语 README 在 `main` 分支。

- `index.html`：产品介绍、安装命令、运行条件与 FAQ。
- `css/style.css`：样式与响应式布局。
- `js/i18n.js`：中英文案和语言选择。
- `js/main.js`：语言、主题、示意动画、复制与最新发布链接。
- `assets/`：图标及 2026-10-09 用户提供的真实应用截图。

在分支根目录运行 `python3 -m http.server 8000` 后打开 `http://localhost:8000` 预览。推送 `gh-pages` 后由 GitHub Pages 发布根目录。截图与特性以最新 `main` 为准；下载按钮对应正式 Release，可能晚于源码。交互动画是排程示意，不代表账号额度承诺。
