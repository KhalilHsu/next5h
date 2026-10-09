/** Next5h website: Chinese and English strings aligned with current source. */
const translations = {
  "zh": {
    "meta.title": "Next5h - macOS 原生 Codex 消息排定与额度看板",
    "meta.description": "排定 Codex 消息、在 5H 额度恢复后继续已有会话，查看额度和派发历史。支持独立开关与晨间 6 Luna / low 预置。",
    "nav.coreValues": "核心价值",
    "nav.pipeline": "执行链路",
    "nav.matrix": "硬件支持矩阵",
    "nav.install": "安装指南",
    "nav.faq": "常见问题",
    "nav.installBtn": "立即安装",
    "nav.langBtn": "EN",
    "nav.themeToggle": "切换暗色/亮色主题",
    "hero.pill": "macOS 原生 · 本地官方 Codex CLI",
    "hero.title": "把下一步任务提前安排好<br><span class=\"hero-title-highlight\">额度恢复后继续 · 每天按时开始</span>",
    "hero.ctaInstall": "⚡️ 开始安装体验",
    "hero.ctaValues": "了解两种使用方式",
    "hero.ctaFaq": "查看常见问题 ➔",
    "hero.copyBtn": "一键复制",
    "hero.copied": "已复制",
    "core.tag": "Core Value Pillars",
    "core.title": "提前排定任务，减少等待",
    "core.desc": "预定消息、选择会话与模型，并随时关闭某一项自动派发。",
    "pillar1.badge": "⚡️ 核心价值 01 · 预定发送",
    "pillar1.title": "当前额度已耗尽？<br>排定恢复后的下一步",
    "pillar1.summary": "选择「5H 解封后」即可按官方重置时间加 1 分钟缓冲排定消息。内置「继续任务」预置默认关闭：先选中要继续的已有会话，再开启。尚未获取重置时间时，该预置会等待额度数据。",
    "pillar1.item1.title": "新建会话或继续已有上下文",
    "pillar1.item1.desc": "支持无项目和本地项目；可新建会话，也可把消息追加到指定的已有会话。",
    "pillar1.item2.title": "模型与推理参数跟随本地目录",
    "pillar1.item2.desc": "从本地 Codex 模型缓存读取可用模型及推理强度、速度选项。晨间预置使用 6 Luna / low；续任务预置使用当前默认模型 / medium。",
    "pillar1.item3.title": "独立开关与后台派发",
    "pillar1.item3.desc": "关闭开关保留内容和参数，重新开启会重算执行时间。后台 CLI 可在锁屏、系统仍运行且网络可用时发送。",
    "pillar2.badge": "⏰ 核心价值 02 · 清晨定时激活",
    "pillar2.title": "清晨先发一条问候<br>按你的节奏开始一天",
    "pillar2.summary": "首次启动预置每日本地时间 07:00 的「嗨」，使用 6 Luna、低推理强度、标准速度，无项目新建会话并在后台发送。已有任务升级后保留保存的配置。",
    "pillar2.slot1.time": "07:00",
    "pillar2.slot1.label": "晨间发送",
    "pillar2.slot2.time": "12:00",
    "pillar2.slot2.label": "5H 时间分段示意",
    "pillar2.slot3.time": "17:00",
    "pillar2.slot3.label": "下一分段示意",
    "pillar2.item1.title": "息屏待命与唤醒尝试",
    "pillar2.item1.desc": "有已排定任务时申请防空闲休眠，并尝试提前 60 秒注册唤醒事件。深度休眠唤醒取决于系统权限和实际设备状态。",
    "pillar2.item2.title": "按时间安排，不改变官方额度",
    "pillar2.item2.desc": "右侧时间轴演示连续 5 小时的时间分段，仅作排程示意。实际额度、窗口和重置时间以账号返回的数据为准。",
    "pillar2.item3.title": "每天循环，随时修改或关闭",
    "pillar2.item3.desc": "支持改时间、内容、目标和模型；也可选择延时或指定日期时间。无需每天重复创建。",
    "pipe.tag": "Local Delivery Pipeline",
    "pipe.title": "从排程到本地会话",
    "pipe.desc": "四种触发策略连接本地 CLI 与桌面会话；执行仍需要应用运行、认证有效和网络可用。",
    "pipe.s1.title": "电源待命守护",
    "pipe.s1.desc": "为已排定任务申请 <code class=\"tech-tag\">PreventUserIdleSystemSleep</code>；尝试提前 60 秒唤醒，注册可能因权限失败。",
    "pipe.s2.title": "网络与额度检查",
    "pipe.s2.desc": "<code class=\"tech-tag\">NetworkMonitor</code> 检查网络；读取模型缓存和账号额度，根据会话活跃状态调整探测频率。",
    "pipe.s3.title": "本地 CLI 后台派发",
    "pipe.s3.desc": "查找官方本地 CLI，新会话使用 <code class=\"tech-tag\">codex exec</code>，已有会话使用 <code class=\"tech-tag\">codex queue</code>，传入所选模型与参数。",
    "pipe.s4.title": "会话同步与派发记录",
    "pipe.s4.desc": "同步本地会话索引与缓存，记录结果、耗时和参数，并提供 <code class=\"tech-tag\">codex://threads/&lt;ID&gt;</code> 会话入口。",
    "matrix.tag": "Reliability Matrix",
    "matrix.title": "🖥️ Mac 锁屏与休眠状态支持矩阵",
    "matrix.desc": "以下说明派发所需条件；并非所有机型与休眠状态都已验证。后台模式需要网络、认证与运行中的系统。",
    "matrix.th.form": "硬件形态",
    "matrix.th.state": "当前电脑状态",
    "matrix.th.power": "供电状态",
    "matrix.th.ability": "预定时间自动发送能力",
    "matrix.th.notes": "技术原理与说明",
    "matrix.r1.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">桌面台式机</small>",
    "matrix.r1.state": "锁屏 / 显示器关闭",
    "matrix.r1.power": "始终连接电源",
    "matrix.r1.status": "可后台发送",
    "matrix.r1.note": "锁屏不阻止 CLI 运行；系统需保持运行，网络和认证有效。",
    "matrix.r2.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">桌面台式机</small>",
    "matrix.r2.state": "系统深度休眠 (Sleep)",
    "matrix.r2.power": "始终连接电源",
    "matrix.r2.status": "取决于唤醒是否成功",
    "matrix.r2.note": "提前 60 秒尝试注册唤醒；权限、系统状态和网络恢复会影响执行。",
    "matrix.r3.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r3.state": "开盖 + 锁屏 / 休眠",
    "matrix.r3.power": "连接电源 (推荐)",
    "matrix.r3.status": "保持运行时可发送",
    "matrix.r3.note": "建议开盖插电。防空闲休眠不等于保证从强制休眠恢复。",
    "matrix.r4.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r4.state": "开盖 + 锁屏 / 休眠",
    "matrix.r4.power": "纯电池供电",
    "matrix.r4.status": "受电量与系统状态影响",
    "matrix.r4.note": "低电量、省电设置和网络恢复可能影响派发，建议插电。",
    "matrix.r5.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r5.state": "合盖 + 接外接显示器<br><small style=\"color: var(--text-muted);\">(Clamshell 合盖模式)</small>",
    "matrix.r5.power": "连接电源",
    "matrix.r5.status": "需合盖桌面模式正常运行",
    "matrix.r5.note": "连接电源与外接显示器，并确认系统保持运行和网络可用。",
    "matrix.r6.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">笔记本形态</small>",
    "matrix.r6.state": "纯合盖 (Lid Closed)<br><small style=\"color: var(--text-muted);\">(无外接显示器，放桌上/包里)</small>",
    "matrix.r6.power": "任意供电",
    "matrix.r6.status": "不保证自动执行",
    "matrix.r6.note": "合盖后的系统休眠与网络状态可能阻止执行，不能依赖防空闲休眠断言恢复。",
    "install.tag": "Quick Installation",
    "install.title": "快速安装部署 Next5h",
    "install.desc": "下载已发布安装包，或从 main 构建最新源码。官网按最新源码介绍，发布包可能滞后。",
    "install.tabSource": "从最新源码构建",
    "install.tabScript": "⚡️ 一键终端安装脚本",
    "install.sourceDesc": "需要 Swift 5.9+ / Xcode Command Line Tools；本地打包后使用临时签名：",
    "install.sourceHint": "安装到应用程序目录：<code>ditto Next5h.app /Applications/Next5h.app</code>",
    "install.scriptDesc": "复制以下单行命令粘贴到 macOS 终端，将自动克隆最新代码、编译 Release 版本并启动：",
    "install.check1.title": "前置环境核验",
    "install.check1.desc": "macOS 14+；兼容的本地官方 Codex CLI 与有效登录。额度探针读取 <code>~/.codex/auth.json</code>；前台发送需要桌面客户端。",
    "install.check2.title": "晨间问候开启，续任务预置关闭",
    "install.check2.desc": "晨间：每日 07:00、6 Luna / low。续任务：当前默认模型 / medium、重置后 +1 分钟；先选择已有会话，再开启开关。",
    "faq.tag": "Got Questions?",
    "faq.title": "常见问题解答 (FAQ)",
    "faq.desc": "关于安全性、唤醒机制与日常使用的常见疑问。",
    "faq.q1": "什么是“预定发送”？它可以发送到指定的 Project 或历史 Session 吗？",
    "faq.a1": "支持无项目或本地项目的新会话，以及追加到已有会话。选择「5H 解封后」按重置时间 +1 分钟排定；续任务预置默认关闭，需选目标会话后开启。历史记录可复制、再次发送、以此为模板新建或删除单条记录。",
    "faq.q2": "晨间预置会改变额度或保证每天三个窗口吗？",
    "faq.a2": "不会。它只是每天本地时间 07:00 发送「嗨」，默认使用 6 Luna / low。实际额度与重置时间由官方决定；页面时间轴是排程示意，不是账号额度承诺。已有任务升级后不会被默认模型覆盖。",
    "faq.q3": "需要额外配置 API Key 吗？认证数据如何使用？",
    "faq.a3": "使用本地 Codex 登录，无需为这条派发链路另填 API Key。额度探针会读取 <code>~/.codex/auth.json</code> 并请求官方后端；任务也会通过官方 CLI 发往服务端。请勿分享认证文件。",
    "faq.q4": "电脑在休眠锁屏状态下，真的能自己唤醒并执行吗？",
    "faq.a4": "锁屏、息屏且系统仍运行时，后台 CLI 可执行。有已排定任务时申请防空闲休眠，同时尝试提前 60 秒注册唤醒。深度休眠恢复取决于注册权限、设备状态和网络；不能保证强制休眠后执行。前台模式需要解锁。",
    "faq.q5": "MacBook 笔记本合盖放进背包里能自动唤醒吗？",
    "faq.a5": "不能依赖纯合盖状态执行。合盖桌面模式需要外接显示器和电源，并确认系统仍在运行；没有外接显示器的合盖状态可能阻止应用与网络工作。",
    "faq.q6": "任务执行完毕后，ChatGPT 桌面客户端需要手动重启才能看到吗？",
    "faq.a6": "后台派发会同步本地会话索引与 SQLite 缓存，并提供 <code>codex://threads/&lt;ID&gt;</code> 链接。能否即时呈现仍取决于安装的桌面客户端是否支持该协议及本地数据格式。",
    "footer.desc": "macOS 原生 Codex 消息排定与额度看板。提前安排任务，保留你的工作节奏。",
    "footer.product": "产品",
    "footer.resources": "资源",
    "footer.repo": "GitHub 仓库",
    "footer.docs": "开发文档",
    "footer.feedback": "反馈与建议",
    "footer.license": "Next5h · 遵循 MIT 开源协议",
    "footer.craft": "Crafted with precision for macOS developers",
    "toast.copied": "已复制到剪贴板！",
    "x.download": "下载 macOS 版",
    "x.notarized": "Apple 公证",
    "x.daily": "每日 07:00",
    "x.stSleep": "待命中",
    "x.stWake": "检查执行条件",
    "x.stSend": "派发中",
    "x.stLive": "发送完成示意",
    "x.seq1": "待命守护 · 尝试注册唤醒",
    "x.seq2": "检查网络连接",
    "x.seq3": "codex exec → 6 Luna / low ·「嗨」",
    "x.seq4": "记录派发结果 · 以实际额度为准",
    "x.qTitle": "待发队列 · 压缩时间演示",
    "x.replay": "重播",
    "x.qRemain": "5H 剩余",
    "x.qReset": "解封倒计时",
    "x.q1": "重构 PaymentService，并补齐单元测试",
    "x.q2": "继续昨晚的迁移：把剩余 3 个表切到新 schema",
    "x.q3": "为 README 写一段英文安装说明",
    "x.qNew": "新建会话",
    "x.qWaiting": "等待解封",
    "x.qSending": "派发中",
    "x.qSent": "已发送",
    "x.dTitle": "排程示意：第一条消息何时发送？",
    "x.dReset": "设为 07:00",
    "x.dFirst": "首条消息",
    "x.dCount": "22:00 前的完整 5H 分段（示意）",
    "x.dlMeta": "Universal · macOS 14 及以上",
    "x.dlBtn": "下载 DMG",
    "x.dlNote": "已发布 DMG 使用 Developer ID 签名与 Apple 公证。拖入「应用程序」即可；最新版源码功能可能尚未包含在发布包中。"
  },
  "en": {
    "meta.title": "Next5h - Native Codex Scheduling & Quota Dashboard for macOS",
    "meta.description": "Schedule Codex prompts, continue existing conversations after a 5H reset, and track quota and delivery history. Includes per-schedule switches and a 6 Luna / low morning preset.",
    "nav.coreValues": "Core Values",
    "nav.pipeline": "Pipeline",
    "nav.matrix": "Compatibility",
    "nav.install": "Installation",
    "nav.faq": "FAQ",
    "nav.installBtn": "Install Now",
    "nav.langBtn": "中文",
    "nav.themeToggle": "Toggle Dark/Light Mode",
    "hero.pill": "Native macOS · Local official Codex CLI",
    "hero.title": "Plan your next Codex task<br><span class=\"hero-title-highlight\">Continue after reset · Start on schedule</span>",
    "hero.ctaInstall": "⚡️ Install & Get Started",
    "hero.ctaValues": "Explore two workflows",
    "hero.ctaFaq": "View FAQ ➔",
    "hero.copyBtn": "Copy Command",
    "hero.copied": "Copied",
    "core.tag": "Core Value Pillars",
    "core.title": "Schedule ahead, spend less time waiting",
    "core.desc": "Queue prompts, choose conversations and models, and pause individual schedules whenever you need.",
    "pillar1.badge": "⚡️ Core Value 01 · Queued Dispatch",
    "pillar1.title": "Out of quota?<br>Queue your next step",
    "pillar1.summary": "Use the 5H-reset trigger to schedule a prompt one minute after the reported reset time. The continuation starter is disabled by default: choose an existing conversation, then enable it. This starter waits if the reset time is not yet available.",
    "pillar1.item1.title": "Start fresh or continue a conversation",
    "pillar1.item1.desc": "Choose no project or a local project, then create a conversation or append to a selected existing one.",
    "pillar1.item2.title": "Models and reasoning from the local catalog",
    "pillar1.item2.desc": "Choose available models, reasoning effort and speed from the local Codex cache. The morning preset uses 6 Luna / low; the continuation starter uses the current default model / medium.",
    "pillar1.item3.title": "Individual switches and background delivery",
    "pillar1.item3.desc": "Pause automatic delivery without losing settings; enabling recalculates the schedule. Background CLI delivery can run while the screen is locked and the system and network remain available.",
    "pillar2.badge": "⏰ Core Value 02 · Morning Scheduled Wakeup",
    "pillar2.title": "Send a morning greeting<br>Start the day on your schedule",
    "pillar2.summary": "First launch creates a daily 07:00 local-time greeting: 嗨, 6 Luna, low reasoning, standard speed, a new conversation without a project, and background delivery. Updates preserve settings saved in existing schedules.",
    "pillar2.slot1.time": "07:00",
    "pillar2.slot1.label": "Morning send",
    "pillar2.slot2.time": "12:00",
    "pillar2.slot2.label": "Illustrative 5H period",
    "pillar2.slot3.time": "17:00",
    "pillar2.slot3.label": "Next illustrative period",
    "pillar2.item1.title": "Display-off standby and wake scheduling",
    "pillar2.item1.desc": "Scheduled tasks request idle-sleep prevention and attempt a wake event 60 seconds ahead. Recovery from sleep depends on permissions and the actual device state.",
    "pillar2.item2.title": "Plan your time; quota remains provider-controlled",
    "pillar2.item2.desc": "The timeline illustrates consecutive five-hour periods for planning. Actual quota, windows and reset times follow the data returned for your account.",
    "pillar2.item3.title": "Repeat daily, edit or pause anytime",
    "pillar2.item3.desc": "Change the time, prompt, destination or model; delay and specific-date triggers are also available. No need to recreate the schedule each day.",
    "pipe.tag": "Local Delivery Pipeline",
    "pipe.title": "From a schedule to a local conversation",
    "pipe.desc": "Four trigger strategies connect the local CLI and desktop conversations. Delivery requires a running app, valid local authentication and network access.",
    "pipe.s1.title": "Power standby guard",
    "pipe.s1.desc": "Request <code class=\"tech-tag\">PreventUserIdleSystemSleep</code> for scheduled tasks and attempt a wake event 60 seconds ahead. Registration may fail because of permissions.",
    "pipe.s2.title": "Network and quota checks",
    "pipe.s2.desc": "<code class=\"tech-tag\">NetworkMonitor</code> checks connectivity; model cache and account quota inform delivery, with probe frequency adapting to session activity.",
    "pipe.s3.title": "Local CLI background delivery",
    "pipe.s3.desc": "Locate the official local CLI, use <code class=\"tech-tag\">codex exec</code> for new conversations or <code class=\"tech-tag\">codex queue</code> for existing ones, and pass the selected model and parameters.",
    "pipe.s4.title": "Conversation sync and delivery history",
    "pipe.s4.desc": "Synchronize local conversation indexes and caches, record results, duration and settings, and provide a <code class=\"tech-tag\">codex://threads/&lt;ID&gt;</code> conversation link.",
    "matrix.tag": "Reliability Matrix",
    "matrix.title": "🖥️ Mac Lock Screen & Sleep Compatibility Matrix",
    "matrix.desc": "These are operating conditions, not a guarantee for every device and sleep state. Background delivery needs network access, authentication and an awake system.",
    "matrix.th.form": "Hardware Form",
    "matrix.th.state": "System State",
    "matrix.th.power": "Power Source",
    "matrix.th.ability": "Scheduled Dispatch Capability",
    "matrix.th.notes": "Technical Principles & Details",
    "matrix.r1.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">Desktop</small>",
    "matrix.r1.state": "Lock Screen / Display Off",
    "matrix.r1.power": "Always Connected",
    "matrix.r1.status": "Background delivery available",
    "matrix.r1.note": "Locking the screen does not block the CLI; the system, network and authentication must remain available.",
    "matrix.r2.form": "<strong>Mac mini / Studio / Pro</strong><br><small style=\"color: var(--text-muted);\">Desktop</small>",
    "matrix.r2.state": "System Deep Sleep",
    "matrix.r2.power": "Always Connected",
    "matrix.r2.status": "Depends on successful wake",
    "matrix.r2.note": "A wake event is attempted 60 seconds ahead; permissions, system state and network recovery affect delivery.",
    "matrix.r3.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r3.state": "Open Lid + Lock / Sleep",
    "matrix.r3.power": "Connected to Power (Recommended)",
    "matrix.r3.status": "Available while awake",
    "matrix.r3.note": "An open lid and AC power are recommended. Idle-sleep prevention does not guarantee recovery from forced sleep.",
    "matrix.r4.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r4.state": "Open Lid + Lock / Sleep",
    "matrix.r4.power": "Battery Power",
    "matrix.r4.status": "Battery and system dependent",
    "matrix.r4.note": "Low battery, power-saving settings and connectivity can affect delivery; AC power is recommended.",
    "matrix.r5.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r5.state": "Closed Lid + External Display<br><small style=\"color: var(--text-muted);\">(Clamshell Mode)</small>",
    "matrix.r5.power": "Connected to Power",
    "matrix.r5.status": "Requires active clamshell mode",
    "matrix.r5.note": "Connect power and an external display, and verify that the system and network remain available.",
    "matrix.r6.form": "<strong>MacBook (Air / Pro)</strong><br><small style=\"color: var(--text-muted);\">Laptop</small>",
    "matrix.r6.state": "Pure Closed Lid<br><small style=\"color: var(--text-muted);\">(No External Display, on desk/in bag)</small>",
    "matrix.r6.power": "Any Power",
    "matrix.r6.status": "Automatic delivery not guaranteed",
    "matrix.r6.note": "Closed-lid sleep and network state may prevent execution; an idle-sleep assertion cannot be relied on to recover the system.",
    "install.tag": "Quick Installation",
    "install.title": "Quick Next5h Deployment",
    "install.desc": "Download a published release or build the latest main source. The site describes current source; published binaries may lag behind it.",
    "install.tabSource": "Build the latest source",
    "install.tabScript": "⚡️ One-Line Terminal Script",
    "install.sourceDesc": "Requires Swift 5.9+ / Xcode Command Line Tools. Package locally, then apply an ad hoc signature:",
    "install.sourceHint": "Install into Applications: <code>ditto Next5h.app /Applications/Next5h.app</code>",
    "install.scriptDesc": "Copy and paste this single command into macOS Terminal to auto-clone, compile Release build, and launch:",
    "install.check1.title": "Prerequisites Check",
    "install.check1.desc": "macOS 14+; a compatible local official Codex CLI and valid login. Quota probes read <code>~/.codex/auth.json</code>; foreground delivery requires the desktop client.",
    "install.check2.title": "Morning on, continuation off",
    "install.check2.desc": "Morning: daily 07:00, 6 Luna / low. Continuation: current default model / medium, reset +1 minute; choose an existing conversation before enabling it.",
    "faq.tag": "Got Questions?",
    "faq.title": "Frequently Asked Questions (FAQ)",
    "faq.desc": "Common questions regarding security, wakeup mechanisms, and daily workflows.",
    "faq.q1": "What is 'Queued Dispatch'? Can it send to specific Projects or historical Sessions?",
    "faq.a1": "Create a conversation with or without a local project, or append to an existing one. The 5H-reset trigger schedules delivery at reset +1 minute. The continuation starter is off until you select a conversation and enable it. History supports copying, resending, creating a schedule from a record, and individual deletion.",
    "faq.q2": "Does the morning preset change quota or guarantee three windows?",
    "faq.a2": "No. It sends 嗨 at 07:00 local time using 6 Luna / low by default. Quota and resets are provider-controlled; the timeline is illustrative. Updates do not overwrite model settings saved in existing schedules.",
    "faq.q3": "Do I need a separate API key? How is authentication used?",
    "faq.a3": "The app uses your local Codex login; this delivery path does not require a separate API key. Quota probes read <code>~/.codex/auth.json</code> and query the official backend; prompts are sent through the official CLI. Keep the authentication file private.",
    "faq.q4": "Can Mac really wake up and execute while sleeping and locked?",
    "faq.a4": "Background CLI delivery can run with a locked or sleeping display while the system is awake. Scheduled tasks request idle-sleep prevention and attempt wake registration 60 seconds ahead. Recovery from system sleep depends on permissions, device state and connectivity; forced sleep is not guaranteed. Foreground delivery needs an unlocked screen.",
    "faq.q5": "Can a MacBook wake up automatically with its lid closed in a backpack?",
    "faq.a5": "Do not rely on standalone closed-lid delivery. Clamshell desktop mode requires an external display and power, with an awake system. A closed lid without an external display may prevent the app and network from operating.",
    "faq.q6": "Do I need to restart the ChatGPT desktop app to see dispatched results?",
    "faq.a6": "Background delivery updates local conversation indexes and SQLite caches, and provides a <code>codex://threads/&lt;ID&gt;</code> link. Presentation depends on the installed desktop client supporting the protocol and local data format.",
    "footer.desc": "Native macOS Codex scheduling and quota tracking. Plan tasks ahead and keep your workflow moving.",
    "footer.product": "Product",
    "footer.resources": "Resources",
    "footer.repo": "GitHub Repository",
    "footer.docs": "Documentation",
    "footer.feedback": "Feedback & Issues",
    "footer.license": "Next5h · Licensed under MIT",
    "footer.craft": "Crafted with precision for macOS developers",
    "toast.copied": "Copied to clipboard!",
    "x.download": "Download for macOS",
    "x.notarized": "Notarized",
    "x.daily": "Daily 07:00",
    "x.stSleep": "Standing by",
    "x.stWake": "Checking readiness",
    "x.stSend": "Dispatching",
    "x.stLive": "Illustrative completion",
    "x.seq1": "Standby guard · attempt wake registration",
    "x.seq2": "Check network connectivity",
    "x.seq3": "codex exec → 6 Luna / low · 嗨",
    "x.seq4": "Record delivery · follow actual quota data",
    "x.qTitle": "Queue · accelerated illustration",
    "x.replay": "Replay",
    "x.qRemain": "5H left",
    "x.qReset": "Resets in",
    "x.q1": "Refactor PaymentService and fill in unit tests",
    "x.q2": "Continue last night's migration: move the last 3 tables to the new schema",
    "x.q3": "Write an English install section for the README",
    "x.qNew": "New session",
    "x.qWaiting": "Waiting",
    "x.qSending": "Sending",
    "x.qSent": "Sent",
    "x.dTitle": "Planning illustration: when is the first prompt?",
    "x.dReset": "Set to 07:00",
    "x.dFirst": "First message",
    "x.dCount": "Illustrative 5H periods before 22:00",
    "x.dlMeta": "Universal · macOS 14 or later",
    "x.dlBtn": "Download DMG",
    "x.dlNote": "Published DMGs are Developer ID signed and Apple notarized. Drag into Applications; the latest source features may not yet be included in the release."
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
  // Check browser/system language preferences
  const languages = navigator.languages || [navigator.language || navigator.userLanguage || ''];
  for (let i = 0; i < languages.length; i++) {
    const l = (languages[i] || '').toLowerCase();
    if (l.startsWith('zh')) {
      return 'zh';
    }
    // If the primary preference is English or any non-Chinese language
    if (i === 0 && !l.startsWith('zh')) {
      return 'en';
    }
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
