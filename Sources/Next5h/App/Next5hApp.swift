import SwiftUI
import AppKit
import Combine

@main
public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static var sharedDelegate: AppDelegate?
    private static let fixedContentWidth: CGFloat = 720

    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    public static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        sharedDelegate = delegate
        app.delegate = delegate
        app.run()
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppIcon()
        setupMainMenu()
        NotificationService.shared.requestAuthorization()
        
        // 1. 初始化顶部状态栏 Item
        setupStatusItem()
        
        // 2. 初始化主面板窗口
        setupMainWindow()
        
        // 3. 监听 QuotaProbeEngine 数据变化，实时重绘双胶囊圆柱
        QuotaProbeEngine.shared.$currentQuota
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemUI()
            }
            .store(in: &cancellables)
        
        // 4. 监听语言切换，实时更新状态栏菜单文案
        LocalizationManager.shared.$currentLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        print("🚀 Next5h 已启动，支持状态栏双圆柱监控与常驻后台运行")
    }
    
    private func setupAppIcon() {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") ?? Bundle.main.path(forResource: "AppIcon", ofType: "png"),
           let image = NSImage(contentsOfFile: iconPath) {
            NSApplication.shared.applicationIconImage = image
        }
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // 1. App 菜单 (无任何多余 Settings 入口)
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L10n.menuOpenWorkbench, action: #selector(handleOpenMainWindow), keyEquivalent: "o")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: L10n.menuQuit, action: #selector(handleQuit), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 2. 编辑菜单 (支持常规快捷键 ⌘C, ⌘V, ⌘X, ⌘A, ⌘Z)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // 3. 窗口菜单 (支持 ⌘W 关闭收起窗口)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemUI()
    }
    
    private func setupMainWindow() {
        let contentView = MainSplitView()
        let hostingView = NSHostingView(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.fixedContentWidth, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "Next5h"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.setContentSize(NSSize(width: Self.fixedContentWidth, height: 640))
        window.contentMinSize = NSSize(width: Self.fixedContentWidth, height: 500)
        window.contentMaxSize = NSSize(width: Self.fixedContentWidth, height: 10_000)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        self.mainWindow = window
        
        // 启动时默认打开窗口并显示 Dock Icon
        showMainWindow()
    }
    
    public func showMainWindow() {
        if mainWindow == nil {
            setupMainWindow()
        }
        if let win = mainWindow {
            var f = win.frame
            f.size.width = Self.fixedContentWidth
            win.setFrame(f, display: true)
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }
    
    // MARK: - NSWindowDelegate (窗口点击红叉时隐藏而不是销毁，并隐藏 Dock 图标)
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        print("📴 主面板已收起，Dock 图标已隐藏，Next5h 转入顶部状态栏常驻运行")
        return false
    }

    /// 固定横向尺寸，只允许用户调整窗口高度。
    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: sender.frame.width, height: frameSize.height)
    }
    
    private func updateStatusItemUI() {
        guard let button = statusItem?.button else { return }
        
        let quota = QuotaProbeEngine.shared.currentQuota
        let rem5h = quota.remainingPercent
        let remWeekly = quota.weeklyRemainingPercent ?? 100.0
        
        let iconImage = StatusItemRenderer.renderDualCylinder(
            remaining5h: rem5h,
            remainingWeekly: remWeekly,
            isLocked: quota.isLocked
        )
        
        button.image = iconImage
        button.imagePosition = .imageOnly
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // 1. 打开主面板
        let openItem = NSMenuItem(title: L10n.menuOpenWorkbench, action: #selector(handleOpenMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. 实时 5H 额度信息
        let quota = QuotaProbeEngine.shared.currentQuota
        let rem5hText = "\(L10n.menuQuota5h) \(Int(quota.remainingPercent))%"
        let resetTimeStr: String
        if let reset = quota.resetsAt {
            let df = DateFormatter()
            df.dateFormat = "HH:mm:ss"
            resetTimeStr = df.string(from: reset)
        } else {
            resetTimeStr = L10n.menuUnrestricted
        }
        let item5h = NSMenuItem(title: "\(rem5hText)  (\(L10n.menuResetAt) \(resetTimeStr))", action: nil, keyEquivalent: "")
        item5h.isEnabled = false
        menu.addItem(item5h)
        
        // 3. 实时 周额度信息
        let remWeekly = quota.weeklyRemainingPercent ?? 100.0
        let itemWeekly = NSMenuItem(title: "\(L10n.menuQuotaWeekly) \(Int(remWeekly))%  (\(quota.formattedWeeklyRemainingTime))", action: nil, keyEquivalent: "")
        itemWeekly.isEnabled = false
        menu.addItem(itemWeekly)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. 语言切换子菜单
        let langMenu = NSMenu()
        let currentLang = LocalizationManager.shared.currentLanguage
        for lang in AppLanguage.allCases {
            let langItem = NSMenuItem(title: lang.displayName, action: #selector(handleSelectLanguage(_:)), keyEquivalent: "")
            langItem.target = self
            langItem.representedObject = lang
            langItem.state = (lang == currentLang) ? .on : .off
            langMenu.addItem(langItem)
        }
        let langParentItem = NSMenuItem(title: L10n.menuLanguageSubmenu, action: nil, keyEquivalent: "")
        langParentItem.submenu = langMenu
        menu.addItem(langParentItem)
        
        // 5. 刷新与退出
        let refreshItem = NSMenuItem(title: L10n.menuRefreshQuota, action: #selector(handleRefreshQuota), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func handleSelectLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? AppLanguage else { return }
        LocalizationManager.shared.setLanguage(lang)
    }
    
    @objc private func handleOpenMainWindow() {
        showMainWindow()
    }
    
    @objc private func handleRefreshQuota() {
        QuotaProbeEngine.shared.refreshNow()
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
