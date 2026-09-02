/**
 * Next5h Official Website - Internationalization (i18n)
 * Supports Chinese (zh) and English (en) with automatic browser detection & manual toggle.
 */

const translations = {
  zh: {
    // Meta
    "meta.title": "Next5h - macOS 原生 Codex 额度预定与清晨定时激活工作台",
    "meta.description": "为 macOS 开发者量身打造的 Codex 5H 窗口自动续航与任务排定工作台。夜间到期硬件唤醒 Mac，通过本地官方 Codex CLI 静默派发任务。",
    
    // Navbar
    "nav.coreValues": "核心价值",
    "nav.pipeline": "执行链路",
    "nav.matrix": "硬件支持矩阵",
    "nav.install": "安装指南",
    "nav.faq": "常见问题",
    "nav.installBtn": "立即安装",
    "nav.langBtn": "EN",
    "nav.themeToggle": "切换暗色/亮色主题",
    
    // Hero
    "hero.pill": "macOS 原生架构 · 榨干 Codex 算力极限",
    "hero.title": "不要浪费任何一个 5H 额度<br><span class=\"hero-title-highlight\">额度到期预定 · 清晨定时激活 · 吃满 3 个窗口</span>",
    "hero.subtitle": "<strong>① 没额度？随时预定</strong>：排队 User Query，解封秒级自动发送至指定 Project / 历史 Session，支持选模型与 Thinking 强度。<br><strong>② 想要算力翻倍？清晨定时</strong>：早晨 07:00 硬件唤醒 Mac 自动发“激活”对话，白天稳稳吃满 3 个完整的 5 小时额度窗口。",
    "hero.ctaInstall": "⚡️ 开始安装体验",
    "hero.ctaValues": "了解 2 大核心玩法 ➔",
    "hero.copyBtn": "一键复制",
    "hero.copied": "已复制",
    
    // Core Values Section
    "core.tag": "Core Value Pillars",
    "core.title": "解决核心痛点：Next5h 的两大核心价值",
    "core.desc": "无需人工值守与死等倒计时，通过原生自动化让每一分订阅价值发挥到极致。",
    
    // Pillar 1
    "pillar1.badge": "⚡️ 核心价值 01 · 预定发送",
    "pillar1.title": "当前无额度？提前排队预定<br>解封秒级自动发送",
    "pillar1.summary": "构思好了 Prompt 却遇到 5H 额度耗尽？无需守在电脑前死等倒计时。在 Next5h 中随时录入 User Query 加入队列，窗口一旦解封，后台立即静默自动派发。",
    "pillar1.item1.title": "精准指定 Project 与历史 Session",
    "pillar1.item1.desc": "不仅支持新立独立会话，更可精确发送到指定项目 (Project) 或追加到历史 Session (Thread)，无缝继承工程上下文。",
    "pillar1.item2.title": "自由选择模型与 Thinking (推理) 强度",
    "pillar1.item2.desc": "支持自由指定模型种类（如 o3-mini、o1、GPT-4o），并自定义 Thinking 推理强度等级 (Low / Medium / High Effort)。",
    "pillar1.item3.title": "锁屏静默执行，零人工值守",
    "pillar1.item3.desc": "直接调用本地官方 Codex CLI，无需亮屏与输入锁屏密码，到点即发，绝不浪费 1 秒钟可用额度。",
    
    // Pillar 2
    "pillar2.badge": "⏰ 核心价值 02 · 清晨定时激活",
    "pillar2.title": "清晨定时发送“激活对话”<br>白天稳稳吃满 3 个窗口",
    "pillar2.summary": "普通用户中午才开工，一天只能消耗 1~2 个 5 小时周期。Next5h 在清晨 07:00 通过硬件 RTC 唤醒 Mac 并发送一条激活消息，提前触发首个滑动窗口计时，全天算力直接翻倍！",
    "pillar2.slot1.time": "07:00",
    "pillar2.slot1.label": "⚡️ 自动激活 (窗口 1)",
    "pillar2.slot2.time": "12:00",
    "pillar2.slot2.label": "🔄 满血重置 (窗口 2)",
    "pillar2.slot3.time": "17:00",
    "pillar2.slot3.label": "🚀 再次重置 (窗口 3)",
    "pillar2.item1.title": "macOS 硬件级 RTC 芯片唤醒",
    "pillar2.item1.desc": "到点前 60s 调用内核 <code>IOPMSchedulePowerEvent</code> 叫醒电脑并恢复 Wi-Fi，早上到工位时第 1 轮额度早已就绪。",
    "pillar2.item2.title": "全天黄金工作时间无缝覆盖",
    "pillar2.item2.desc": "3 个完整 5 小时窗口完美覆盖 07:00~22:00，告别下午才开启第 1 个窗口的巨大浪费，榨干每一分算力。",
    "pillar2.item3.title": "一键开启，每天自动循环",
    "pillar2.item3.desc": "预置每天 07:00 执行规则，支持自定义激活 Prompt 与目标会话，静默运行无需每天重复设置。",

    // Pipeline Section
    "pipe.tag": "Zero Hassle Pipeline",
    "pipe.title": "全链路自动化：从硬件唤醒到无感刷新",
    "pipe.desc": "Next5h 深度整合 macOS 底层电源管理接口与官方 Codex CLI，让任务派发在深睡与锁屏状态下也能完美完成。",
    "pipe.s1.title": "硬件 RTC 芯片定时唤醒",
    "pipe.s1.desc": "调用 macOS <code class=\"tech-tag\">IOPMSchedulePowerEvent</code> 内核接口，在任务到点前 60s 硬件叫醒 Mac，并申请电源守护阻止深睡断网。",
    "pipe.s2.title": "Wi-Fi 网络自愈与模型探针",
    "pipe.s2.desc": "唤醒后，内置 <code class=\"tech-tag\">NetworkMonitor</code> 追踪网络握手，并实时读取官方模型缓存与 5H 额度重置倒计时。",
    "pipe.s3.title": "本地 Codex CLI 静默派发",
    "pipe.s3.desc": "直调官方 <code class=\"tech-tag\">ChatGPT.app/.../codex</code> CLI，精准派发至指定 Project 或历史 Session，支持选模型与 Thinking 强度，锁屏免密执行。",
    "pipe.s4.title": "codex:// 免重启即时呈现",
    "pipe.s4.desc": "同步更新本地 session 会话索引与 SQLite 缓存，通过 <code class=\"tech-tag\">codex://threads/&lt;ID&gt;</code> 深度协议让运行中的桌面端无感刷新。",

    // Matrix Section
    "matrix.tag": "Reliability Matrix",
    "matrix.title": "🖥️ Mac 锁屏与休眠状态支持矩阵",
    "matrix.desc": "我们对主流 Apple Silicon 与 Intel Mac 设备进行了严格的实机休眠唤醒测试，技术边界透明清晰。",
    "matrix.th.form": "硬件形态",
    "matrix.th.state": "当前电脑状态",
    "matrix.th.power": "供电状态",
    "matrix.th.ability": "预定时间自动发送能力",
    "matrix.th.notes": "技术原理与说明",
    "matrix.r1.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">桌面台式机</small>",
    "matrix.r1.state": "锁屏 / 显示器关闭",
    "matrix.r1.power": "始终连接电源",
    "matrix.r1.status": "🟢 100% 完美发送",
    "matrix.r1.note": "系统内核常驻运行，静默 CLI 模式无需屏幕解锁与前台焦点。",
    "matrix.r2.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">桌面台式机</small>",
    "matrix.r2.state": "系统深度休眠 (Sleep)",
    "matrix.r2.power": "始终连接电源",
    "matrix.r2.status": "🟢 自动唤醒并发送",
    "matrix.r2.note": "到点前 60s RTC 硬件叫醒 Mac，Wi-Fi 握手完成后静默执行。",
    "matrix.r3.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r3.state": "开盖 + 锁屏 / 休眠",
    "matrix.r3.power": "连接电源 (推荐)",
    "matrix.r3.status": "🟢 100% 稳定发送",
    "matrix.r3.note": "RTC 正常硬件唤醒，AC 供电下网络即时恢复并派发任务。",
    "matrix.r4.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r4.state": "开盖 + 锁屏 / 休眠",
    "matrix.r4.power": "纯电池供电",
    "matrix.r4.status": "🟡 支持 (电量敏感)",
    "matrix.r4.note": "支持 RTC 唤醒，但极端低电量或省电模式可能延迟 Wi-Fi 握手，建议插电。",
    "matrix.r5.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r5.state": "合盖 + 接外接显示器<br><small style=\"color: var(--text-muted);\">(Clamshell 合盖模式)</small>",
    "matrix.r5.power": "连接电源",
    "matrix.r5.status": "🟢 100% 稳定发送",
    "matrix.r5.note": "macOS 官方合盖台式机工作模式，插电即可全速常驻运行。",
    "matrix.r6.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r6.state": "纯合盖 (Lid Closed)<br><small style=\"color: var(--text-muted);\">(无外接显示器，放桌上/包里)</small>",
    "matrix.r6.power": "任意供电",
    "matrix.r6.status": "🔴 无法保证 (系统限制)",
    "matrix.r6.note": "<strong>macOS 固件安全限制</strong>：Apple Silicon 在纯合盖时为防包内过热，会切断 Wi-Fi 并强制深睡。",

    // Installation Section
    "install.tag": "Quick Installation",
    "install.title": "快速安装部署 Next5h",
    "install.desc": "我们为不同偏好的开发者提供了灵活的安装方式，从一键终端脚本到源码编译，开箱即用。",
    "install.tabSource": "💻 源码克隆与编译构建 (推荐)",
    "install.tabScript": "⚡️ 一键终端安装脚本",
    "install.sourceDesc": "使用 Swift Package Manager 原生 Release 编译模式，打包生成标准独立的 <code>Next5h.app</code>：",
    "install.sourceHint": "💡 提示：如需安装至系统应用程序目录，可直接执行：<code>cp -R Next5h.app /Applications/</code>",
    "install.scriptDesc": "复制以下单行命令粘贴到 macOS 终端，将自动克隆最新代码、编译 Release 版本并启动：",
    "install.check1.title": "前置环境核验",
    "install.check1.desc": "macOS 14.0 (Sonoma) 或更高版本；已安装官方 ChatGPT macOS 客户端 (<code>/Applications/ChatGPT.app</code>)。",
    "install.check2.title": "预置 07:00 任务自动生效",
    "install.check2.desc": "初次启动自动创建每天 07:00 执行的预置任务，并注册硬件 RTC 闹钟，点击卡片可随时就地编辑。",

    // FAQ Section
    "faq.tag": "Got Questions?",
    "faq.title": "常见问题解答 (FAQ)",
    "faq.desc": "关于安全性、唤醒机制与日常使用的常见疑问。",
    "faq.q1": "什么是“预定发送”？它可以发送到指定的 Project 或历史 Session 吗？",
    "faq.a1": "<strong>完全支持。</strong> 当当前 5 小时窗口额度耗尽时，你无需守在电脑前死等倒计时。直接在 Next5h 中录入想发送的 User Query 加入预定队列。5H 窗口解封瞬间，后台会自动静默派发。你可以选择创建全新独立会话，也可以精准指定发送到 ChatGPT 中已有的 <strong>Project (项目)</strong> 或追加到<strong>历史 Session (会话 Thread)</strong>，无缝延续代码上下文；并可自由指定模型与 Thinking 推理强度。",
    "faq.q2": "为什么要“清晨定时发送”？它是如何帮我白天吃满 3 个 5 小时窗口的？",
    "faq.a2": "<strong>核心在于抢先触发滑动窗口计时。</strong> 官方 5H 额度是从你当天发送“第一条消息”起才开始倒计时 5 小时。如果上午 11 点才发首条消息，一天最多只能消耗 1~2 轮。Next5h 每天清晨 07:00 通过硬件 RTC 唤醒电脑发送激活对话，提前开启第 1 个窗口。这样 <strong>07:00 (窗口1) ➔ 12:00 (窗口2) ➔ 17:00 (窗口3)</strong>，在白天正常工作时间内可以稳稳用满 3 个完整周期，算力价值彻底翻倍！",
    "faq.q3": "Next5h 是否需要配置 OpenAI API Key 或输入账号密码？",
    "faq.a3": "<strong>完全不需要。</strong> Next5h 直接复用官方 ChatGPT macOS 客户端的本地登录认证态，底层调用 <code>/Applications/ChatGPT.app/Contents/Resources/codex</code> 官方原生二进制，零额外密钥依赖，安全纯粹。",
    "faq.q4": "电脑在休眠锁屏状态下，真的能自己唤醒并执行吗？",
    "faq.a4": "<strong>可以。</strong> Next5h 基于 macOS 核心服务中的 <code>IOPMSchedulePowerEvent</code> 硬件内核接口，提前 60 秒叫醒 Mac，随后申请 <code>PreventUserIdleSystemSleep</code> 阻止系统深睡，通过静默 CLI 模式执行，无需输入锁屏密码。",
    "faq.q5": "MacBook 笔记本合盖放进背包里能自动唤醒吗？",
    "faq.a5": "<strong>纯合盖且无外接显示器状态下不建议。</strong> Apple Silicon 固件为了防止电脑在密闭背包中过热造成硬件损害，在纯合盖时会彻底关闭 Wi-Fi 芯片并进入强制低功耗。如果是接了外接显示器并插电的合盖状态（Clamshell Mode），则 100% 完美支持。",
    "faq.q6": "任务执行完毕后，ChatGPT 桌面客户端需要手动重启才能看到吗？",
    "faq.a6": "<strong>免重启即时呈现。</strong> Next5h 会自动更新 <code>~/.codex/session_index.jsonl</code> 与 SQLite 缓存，并通过 <code>codex://threads/&lt;ID&gt;</code> 深度协议直接通知运行中的 ChatGPT 客户端无感刷新会话树。",

    // Footer
    "footer.desc": "macOS 原生 Codex 5H 自动续航与任务排定工作台。专为 macOS 开发者打造，释放算力极限。",
    "footer.product": "产品",
    "footer.resources": "资源",
    "footer.repo": "GitHub 仓库",
    "footer.docs": "开发文档",
    "footer.feedback": "反馈与建议",
    "footer.license": "Next5h · 遵循 MIT 开源协议",
    "footer.craft": "Crafted with precision for macOS developers",
    "toast.copied": "已复制到剪贴板！"
  },
  en: {
    // Meta
    "meta.title": "Next5h - macOS Native Codex 5H Auto-Renew & Task Scheduler",
    "meta.description": "The macOS native Codex 5H window auto-renew and scheduling workbench. Hardware-wakes your Mac upon quota reset and silently dispatches queries via the local official Codex CLI.",

    // Navbar
    "nav.coreValues": "Core Values",
    "nav.pipeline": "Pipeline",
    "nav.matrix": "Compatibility",
    "nav.install": "Installation",
    "nav.faq": "FAQ",
    "nav.installBtn": "Install Now",
    "nav.langBtn": "中文",
    "nav.themeToggle": "Toggle Dark/Light Mode",

    // Hero
    "hero.pill": "macOS Native Architecture · Maximize Codex Compute Limits",
    "hero.title": "Never Waste a Single 5H Quota<br><span class=\"hero-title-highlight\">Quota Reset Queue · Morning Scheduled Wakeup · Max 3 Daily Windows</span>",
    "hero.subtitle": "<strong>① Out of Quota? Queue Anytime</strong>: Stage your User Query into queue. Dispatches the exact second your window resets to specified Projects/Sessions with custom Models and Thinking effort.<br><strong>② Double Your Compute? Morning Schedule</strong>: Automatically hardware-wakes your Mac at 07:00 AM to send an activation ping, unlocking a full 3 five-hour windows throughout your workday.",
    "hero.ctaInstall": "⚡️ Install & Get Started",
    "hero.ctaValues": "Explore 2 Core Pillars ➔",
    "hero.copyBtn": "Copy Command",
    "hero.copied": "Copied",

    // Core Values Section
    "core.tag": "Core Value Pillars",
    "core.title": "Solving Core Pain Points: The 2 Value Pillars of Next5h",
    "core.desc": "Eliminate manual waiting and timer watching. Maximize every ounce of your subscription with native macOS automation.",

    // Pillar 1
    "pillar1.badge": "⚡️ Core Value 01 · Queued Dispatch",
    "pillar1.title": "Out of Quota? Queue Ahead<br>Instant Auto-Dispatch upon Reset",
    "pillar1.summary": "Have a prompt ready but hit the 5H quota limit? No need to stay glued to your screen watching countdowns. Stage your User Query in Next5h — the instant your 5H window resets, it silently dispatches in the background.",
    "pillar1.item1.title": "Pinpoint Project & Historical Session Targeting",
    "pillar1.item1.desc": "Supports not only fresh sessions, but also precisely targeting designated Projects or appending to historical Sessions (Threads) to seamlessly preserve code context.",
    "pillar1.item2.title": "Full Model Selection & Thinking Effort Control",
    "pillar1.item2.desc": "Freely choose model variants (e.g., o3-mini, o1, GPT-4o) and configure Thinking reasoning effort levels (Low / Medium / High Effort).",
    "pillar1.item3.title": "Lock Screen Silent Execution, Zero Manual Supervision",
    "pillar1.item3.desc": "Calls the local official Codex CLI directly. No screen wake or lock screen password required — executes immediately on time.",

    // Pillar 2
    "pillar2.badge": "⏰ Core Value 02 · Morning Scheduled Wakeup",
    "pillar2.title": "Scheduled Morning Activation<br>Easily Max Out 3 Daily Windows",
    "pillar2.summary": "Most developers send their first prompt at noon, squeezing out only 1~2 five-hour cycles daily. Next5h hardware-wakes your Mac at 07:00 AM to send an activation query, triggering your first sliding window early and doubling daily compute capacity!",
    "pillar2.slot1.time": "07:00",
    "pillar2.slot1.label": "⚡️ Auto-Activate (Window 1)",
    "pillar2.slot2.time": "12:00",
    "pillar2.slot2.label": "🔄 Full Reset (Window 2)",
    "pillar2.slot3.time": "17:00",
    "pillar2.slot3.label": "🚀 Final Reset (Window 3)",
    "pillar2.item1.title": "macOS Hardware-Level RTC Chip Wakeup",
    "pillar2.item1.desc": "Invokes the kernel <code>IOPMSchedulePowerEvent</code> 60s ahead to wake Mac and reconnect Wi-Fi. Your fresh quota is ready before you reach your desk.",
    "pillar2.item2.title": "Seamless Coverage of Prime Workday Hours",
    "pillar2.item2.desc": "3 complete 5-hour windows perfectly cover 07:00~22:00, eliminating the waste of opening the first window in the late afternoon.",
    "pillar2.item3.title": "One-Click Enable, Daily Auto-Recurrence",
    "pillar2.item3.desc": "Pre-configured 07:00 AM daily schedule with customizable activation prompts and target sessions. Runs silently without daily setup.",

    // Pipeline Section
    "pipe.tag": "Zero Hassle Pipeline",
    "pipe.title": "End-to-End Automation: From Hardware Wakeup to Instant Refresh",
    "pipe.desc": "Next5h deeply integrates macOS kernel power management APIs with the official Codex CLI, ensuring flawless dispatch even in deep sleep and lock screen states.",
    "pipe.s1.title": "Hardware RTC Chip Scheduled Wakeup",
    "pipe.s1.desc": "Calls macOS <code class=\"tech-tag\">IOPMSchedulePowerEvent</code> kernel API 60s ahead to wake Mac and assertions to prevent sleep network disconnects.",
    "pipe.s2.title": "Wi-Fi Self-Healing & Model Probes",
    "pipe.s2.desc": "Upon waking, built-in <code class=\"tech-tag\">NetworkMonitor</code> verifies Wi-Fi handshake and reads local models cache & 5H reset countdown in real-time.",
    "pipe.s3.title": "Silent Local Codex CLI Dispatch",
    "pipe.s3.desc": "Directly invokes official <code class=\"tech-tag\">ChatGPT.app/.../codex</code> CLI with specified Project/Session & Thinking effort. Executes under lock screen without passwords.",
    "pipe.s4.title": "codex:// Zero-Restart Live Presentation",
    "pipe.s4.desc": "Synchronously updates local session indexes & SQLite cache, notifying active ChatGPT desktop windows via <code class=\"tech-tag\">codex://threads/&lt;ID&gt;</code> without manual restarts.",

    // Matrix Section
    "matrix.tag": "Reliability Matrix",
    "matrix.title": "🖥️ Mac Lock Screen & Sleep Compatibility Matrix",
    "matrix.desc": "We conducted thorough physical sleep/wake testing on Apple Silicon and Intel Macs with transparent technical boundaries.",
    "matrix.th.form": "Hardware Form",
    "matrix.th.state": "System State",
    "matrix.th.power": "Power Source",
    "matrix.th.ability": "Scheduled Dispatch Capability",
    "matrix.th.notes": "Technical Principles & Details",
    "matrix.r1.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">Desktop</small>",
    "matrix.r1.state": "Lock Screen / Display Off",
    "matrix.r1.power": "Always Connected",
    "matrix.r1.status": "🟢 100% Reliable Dispatch",
    "matrix.r1.note": "Kernel daemon continuously active; silent CLI requires no screen unlock or focus.",
    "matrix.r2.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">Desktop</small>",
    "matrix.r2.state": "System Deep Sleep",
    "matrix.r2.power": "Always Connected",
    "matrix.r2.status": "🟢 Auto Wake & Dispatch",
    "matrix.r2.note": "RTC wakes Mac 60s before schedule; Wi-Fi handshake completes then executes silently.",
    "matrix.r3.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r3.state": "Open Lid + Lock / Sleep",
    "matrix.r3.power": "Connected to Power (Recommended)",
    "matrix.r3.status": "🟢 100% Stable Dispatch",
    "matrix.r3.note": "RTC wakes hardware normally; network recovers immediately under AC power.",
    "matrix.r4.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r4.state": "Open Lid + Lock / Sleep",
    "matrix.r4.power": "Battery Power",
    "matrix.r4.status": "🟡 Supported (Battery Sensitive)",
    "matrix.r4.note": "RTC wakeup supported, but low battery or power-saving modes may delay Wi-Fi. AC recommended.",
    "matrix.r5.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r5.state": "Closed Lid + External Display<br><small style=\"color: var(--text-muted);\">(Clamshell Mode)</small>",
    "matrix.r5.power": "Connected to Power",
    "matrix.r5.status": "🟢 100% Stable Dispatch",
    "matrix.r5.note": "Official macOS desktop clamshell mode; runs at full capability when plugged in.",
    "matrix.r6.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r6.state": "Pure Closed Lid<br><small style=\"color: var(--text-muted);\">(No External Display, on desk/in bag)</small>",
    "matrix.r6.power": "Any Power",
    "matrix.r6.status": "🔴 Not Guaranteed (OS Limit)",
    "matrix.r6.note": "<strong>macOS Firmware Safety Limit</strong>: Apple Silicon cuts Wi-Fi and forces deep sleep when closed to prevent bag overheating.",

    // Installation Section
    "install.tag": "Quick Installation",
    "install.title": "Quick Next5h Deployment",
    "install.desc": "We provide flexible installation methods for all developer workflows, from one-line terminal scripts to source compilation.",
    "install.tabSource": "💻 Source Clone & Build (Recommended)",
    "install.tabScript": "⚡️ One-Line Terminal Script",
    "install.sourceDesc": "Build a native, standalone <code>Next5h.app</code> in Release mode using Swift Package Manager:",
    "install.sourceHint": "💡 Tip: To install into your Applications folder, run: <code>cp -R Next5h.app /Applications/</code>",
    "install.scriptDesc": "Copy and paste this single command into macOS Terminal to auto-clone, compile Release build, and launch:",
    "install.check1.title": "Prerequisites Check",
    "install.check1.desc": "macOS 14.0 (Sonoma) or newer; official ChatGPT macOS client installed (<code>/Applications/ChatGPT.app</code>).",
    "install.check2.title": "Pre-Set 07:00 AM Schedule Active",
    "install.check2.desc": "Initial launch automatically creates a daily 07:00 AM task with hardware RTC registration. Editable anytime.",

    // FAQ Section
    "faq.tag": "Got Questions?",
    "faq.title": "Frequently Asked Questions (FAQ)",
    "faq.desc": "Common questions regarding security, wakeup mechanisms, and daily workflows.",
    "faq.q1": "What is 'Queued Dispatch'? Can it send to specific Projects or historical Sessions?",
    "faq.a1": "<strong>Fully supported.</strong> When your current 5-hour quota is exhausted, you don't need to watch countdown timers. Simply stage your User Query into Next5h's queue. The instant the 5H window unlocks, it dispatches silently in the background. You can create brand new sessions or pinpoint designated <strong>Projects</strong> or append to existing <strong>Session Threads</strong> to seamlessly continue code context, with custom models and Thinking effort.",
    "faq.q2": "Why use 'Morning Scheduled Wakeup'? How does it achieve 3 full windows daily?",
    "faq.a2": "<strong>The secret is early sliding window activation.</strong> OpenAI's 5H quota countdown only begins when you send your first message of the day. Starting at 11:00 AM limits you to 1~2 cycles. Next5h hardware-wakes your Mac at 07:00 AM to send an activation prompt, triggering Window 1 early. This enables <strong>07:00 (Window 1) ➔ 12:00 (Window 2) ➔ 17:00 (Window 3)</strong> across normal workday hours, effectively doubling compute value!",
    "faq.q3": "Does Next5h require an OpenAI API Key or account credentials?",
    "faq.a3": "<strong>Not at all.</strong> Next5h directly leverages the local session authentication of your official ChatGPT macOS client, invoking the native binary at <code>/Applications/ChatGPT.app/Contents/Resources/codex</code>. Zero API keys, 100% private and secure.",
    "faq.q4": "Can Mac really wake up and execute while sleeping and locked?",
    "faq.a4": "<strong>Yes.</strong> Next5h relies on the macOS kernel API <code>IOPMSchedulePowerEvent</code> to hardware-wake your Mac 60 seconds before execution, then asserts <code>PreventUserIdleSystemSleep</code> to run in silent CLI mode without requiring lock screen passwords.",
    "faq.q5": "Can a MacBook wake up automatically with its lid closed in a backpack?",
    "faq.a5": "<strong>Not recommended for closed-lid standalone bags.</strong> Apple Silicon firmware disables Wi-Fi and forces ultra-low power to prevent thermal damage inside enclosed bags. However, in Clamshell Mode (closed lid connected to external display and power), it works with 100% reliability.",
    "faq.q6": "Do I need to restart the ChatGPT desktop app to see dispatched results?",
    "faq.a6": "<strong>Instant zero-restart presentation.</strong> Next5h automatically synchronizes <code>~/.codex/session_index.jsonl</code> and SQLite caches, notifying active ChatGPT desktop windows via <code>codex://threads/&lt;ID&gt;</code> protocol to refresh the conversation tree seamlessly.",

    // Footer
    "footer.desc": "macOS Native Codex 5H Auto-Renew & Task Scheduler Workbench. Built for developers to maximize compute limits.",
    "footer.product": "Product",
    "footer.resources": "Resources",
    "footer.repo": "GitHub Repository",
    "footer.docs": "Documentation",
    "footer.feedback": "Feedback & Issues",
    "footer.license": "Next5h · Licensed under MIT",
    "footer.craft": "Crafted with precision for macOS developers",
    "toast.copied": "Copied to clipboard!"
  }
};

/**
 * Determine user language:
 * 1. Saved preference in localStorage ('zh' or 'en')
 * 2. Browser language (if starts with 'zh' -> 'zh', else fallback to 'en')
 */
function getPreferredLanguage() {
  const saved = localStorage.getItem('next5h-lang');
  if (saved && (saved === 'zh' || saved === 'en')) {
    return saved;
  }
  const browserLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
  if (browserLang.startsWith('zh')) {
    return 'zh';
  }
  return 'en';
}

let currentLanguage = getPreferredLanguage();

/**
 * Apply a given language ('zh' or 'en') to the document
 */
function applyLanguage(lang) {
  currentLanguage = lang;
  localStorage.setItem('next5h-lang', lang);
  const dict = translations[lang] || translations.en;

  // 1. Update HTML tag
  document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';

  // 2. Update Document Meta
  if (dict['meta.title']) {
    document.title = dict['meta.title'];
  }
  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc && dict['meta.description']) {
    metaDesc.setAttribute('content', dict['meta.description']);
  }

  // 3. Update Elements with data-i18n (plain text)
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (dict[key] !== undefined) {
      el.textContent = dict[key];
    }
  });

  // 4. Update Elements with data-i18n-html (HTML content)
  document.querySelectorAll('[data-i18n-html]').forEach((el) => {
    const key = el.getAttribute('data-i18n-html');
    if (dict[key] !== undefined) {
      el.innerHTML = dict[key];
    }
  });

  // 5. Update Language Toggle Button Label
  const langBtn = document.getElementById('lang-toggle-btn');
  if (langBtn) {
    const labelSpan = langBtn.querySelector('.lang-btn-text');
    if (labelSpan) {
      // In Chinese mode, show 'EN' button to switch to English; in English mode, show '中文' button to switch to Chinese
      labelSpan.textContent = lang === 'zh' ? 'EN' : '中文';
    }
    langBtn.setAttribute('title', lang === 'zh' ? 'Switch to English' : '切换为中文');
    langBtn.setAttribute('aria-label', lang === 'zh' ? 'Switch to English' : '切换为中文');
  }
}

/**
 * Toggle Language between 'zh' and 'en'
 */
function toggleLanguage() {
  const nextLang = currentLanguage === 'zh' ? 'en' : 'zh';
  applyLanguage(nextLang);
}

// Global export
window.Next5h_i18n = {
  getPreferredLanguage,
  applyLanguage,
  toggleLanguage,
  translations,
  getCurrentLanguage: () => currentLanguage
};
