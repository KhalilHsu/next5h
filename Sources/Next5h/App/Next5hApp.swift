import SwiftUI
import AppKit
import Combine

@main
struct Next5hApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        print("🚀 Next5h 已启动，支持状态栏双圆柱监控与常驻后台运行")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemUI()
    }
    
    private func setupMainWindow() {
        let contentView = MainSplitView()
        let hostingView = NSHostingView(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Next5hMainWindow")
        window.contentView = hostingView
        window.title = "Next5h - Codex 5H 自动续航工作台"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
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
        let openItem = NSMenuItem(title: "🖥️ 打开 Next5h 工作台", action: #selector(handleOpenMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. 实时 5H 额度信息
        let quota = QuotaProbeEngine.shared.currentQuota
        let rem5hText = "🟢 5H 剩余: \(Int(quota.remainingPercent))%"
        let resetTimeStr: String
        if let reset = quota.resetsAt {
            let df = DateFormatter()
            df.dateFormat = "HH:mm:ss"
            resetTimeStr = df.string(from: reset)
        } else {
            resetTimeStr = "未受限"
        }
        let item5h = NSMenuItem(title: "\(rem5hText)  (重置: \(resetTimeStr))", action: nil, keyEquivalent: "")
        item5h.isEnabled = false
        menu.addItem(item5h)
        
        // 3. 实时 周额度信息
        let remWeekly = quota.weeklyRemainingPercent ?? 100.0
        let itemWeekly = NSMenuItem(title: "🔵 周额度剩余: \(Int(remWeekly))%  (\(quota.formattedWeeklyRemainingTime))", action: nil, keyEquivalent: "")
        itemWeekly.isEnabled = false
        menu.addItem(itemWeekly)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. 刷新与退出
        let refreshItem = NSMenuItem(title: "🔄 立即刷新额度", action: #selector(handleRefreshQuota), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let quitItem = NSMenuItem(title: "退出 Next5h", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
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
