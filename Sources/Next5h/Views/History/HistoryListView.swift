import SwiftUI
import AppKit

public struct HistoryListView: View {
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    @State private var filterSelection: HistoryFilter = .all
    @State private var showClearConfirmation: Bool = false
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
    public init() {}
    
    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "all"
        case success = "success"
        case failure = "failure"
        
        public var id: String { rawValue }
        
        public var label: String {
            let isZh = LocalizationManager.shared.currentLanguage == .zh
            switch self {
            case .all: return isZh ? "全部" : "All"
            case .success: return isZh ? "成功" : "Success"
            case .failure: return isZh ? "失败" : "Failure"
            }
        }
    }
    
    private var filteredRecords: [DispatchHistoryRecord] {
        switch filterSelection {
        case .all:
            return historyManager.records
        case .success:
            return historyManager.records.filter { $0.isSuccess }
        case .failure:
            return historyManager.records.filter { !$0.isSuccess }
        }
    }
    
    private var successRateText: String {
        guard !historyManager.records.isEmpty else { return "100%" }
        let successCount = historyManager.records.filter { $0.isSuccess }.count
        let rate = Double(successCount) / Double(historyManager.records.count) * 100.0
        return "\(Int(rate))%"
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部标题与统计栏 (无分割线，严格对齐)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Text(L10n.historyTitle)
                                .font(.title3.bold())
                            
                            if !historyManager.records.isEmpty {
                                Text(L10n.historyTotalCount(historyManager.records.count))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(L10n.historySubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    if !historyManager.records.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label(L10n.historyClearAll, systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 2)
                
                // 统计仪表条与过滤筛选器 (已移除上下所有分割线，与卡片严格左对齐)
                HStack(alignment: .center) {
                    // 快捷统计指标
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text(L10n.historyTodaySuccess)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(historyManager.todaySuccessCount)" + (isZh ? " 次" : ""))
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        
                        HStack(spacing: 4) {
                            Text(L10n.historySuccessRate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(successRateText)
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // 状态筛选器
                    Picker("", selection: $filterSelection) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                .padding(.vertical, 2)
                
                // 历史流水列表 (使用 LazyVStack 保证与上方所有文字/指标 100% 像素级对齐)
                if filteredRecords.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 36)
                        Image(systemName: historyManager.records.isEmpty ? "clock.arrow.circlepath" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.tertiary)
                        
                        Text(historyManager.records.isEmpty ? L10n.historyEmptyTitle : (isZh ? "当前筛选条件下无记录" : "No records for this filter"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(historyManager.records.isEmpty ? L10n.historyEmptySubtitle : (isZh ? "您可以切换筛选器查看全部记录。" : "You can switch filters to view all records."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRecords) { record in
                            HistoryRecordRowView(record: record)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            L10n.historyClearConfirmTitle,
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.confirmClear, role: .destructive) {
                historyManager.clearAll()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.historyClearConfirmMessage)
        }
    }
}

struct HistoryRecordRowView: View {
    let record: DispatchHistoryRecord
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    @State private var hasCopied = false
    @State private var isResending = false
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
    private func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "\(isZh ? "今天" : "Today") HH:mm:ss"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "\(isZh ? "昨天" : "Yesterday") HH:mm:ss"
        } else {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部状态条：状态灯 + 任务标题 + 耗时 + 时间
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(record.isSuccess ? .green : .red)
                
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // 耗时徽章
                if record.durationSeconds > 0 {
                    Text(String(format: "%.1fs", record.durationSeconds))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                        .foregroundStyle(.secondary)
                }
                
                // 派发时间
                Text(formatDateTime(record.dispatchedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // 参数属性行 (模型、推理强度、派发方式、触发方式)
            HStack(spacing: 8) {
                Text(record.modelDisplayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
                
                Text(isZh ? "推理: \(record.reasoningEffort)" : "Effort: \(record.reasoningEffort)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    .foregroundStyle(.secondary)
                
                Text(record.dispatchMode == .silentAPI ? (isZh ? "静默 CLI" : "Silent CLI") : (isZh ? "前台 GUI" : "Foreground GUI"))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                    .foregroundStyle(.blue)
                
                Text(record.triggerStrategySummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // 目标归属
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(record.destinationSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let sessionId = record.targetSessionId, !sessionId.isEmpty {
                    Text(isZh ? "• 会话: \(sessionId.prefix(8))..." : "• Session: \(sessionId.prefix(8))...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            // Prompt 内容预览区
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isZh ? "User Query 内容:" : "User Query Content:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(record.prompt, forType: .string)
                        hasCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopied = false
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                            Text(hasCopied ? (isZh ? "已复制" : "Copied") : (isZh ? "复制" : "Copy"))
                        }
                        .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                }
                
                Text(record.prompt)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor).opacity(0.8)))
            }
            
            // 若失败，展示错误信息提示条
            if !record.isSuccess, let err = record.errorMessage, !err.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(isZh ? "错误详情: \(err)" : "Error: \(err)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.08)))
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // 底部操作按钮栏
            HStack(spacing: 12) {
                // 1. 再次发送
                Button {
                    resendJob()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(isZh ? "再次发送" : "Resend")
                    }
                    .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                .disabled(isResending)
                
                // 2. 以此历史记录为模板新建任务 (直接唤起 Sheet)
                Button {
                    loadIntoComposer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.badge.plus")
                        Text(isZh ? "以此为模板新建" : "Use as Template")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                
                // 3. 在 Codex 中打开会话
                if let sessionId = record.targetSessionId, !sessionId.isEmpty {
                    Button {
                        if let url = URL(string: "codex://threads/\(sessionId)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")
                            Text(isZh ? "在 Codex 中打开" : "Open in Codex")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                // 4. 删除单条记录
                Button(role: .destructive) {
                    historyManager.deleteRecord(id: record.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 11).fill(Color(nsColor: .controlBackgroundColor).opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.primary.opacity(0.08), lineWidth: 0.8))
    }
    
    private func resendJob() {
        isResending = true
        let model = ModelCatalogService.shared.resolveModel(slugOrName: record.modelSlug)
        
        let effort: ReasoningEffort
        switch record.reasoningEffort {
        case "轻度", "low": effort = .low
        case "中", "medium": effort = .medium
        case "高", "high": effort = .high
        case "极高", "xhigh": effort = .xhigh
        case "Max", "max": effort = .max
        case "Ultra", "ultra": effort = .ultra
        default: effort = .low
        }
        
        var destination = TargetDestination()
        if let sId = record.targetSessionId, !sId.isEmpty {
            destination.conversationAction = .existing(id: sId, title: isZh ? "历史会话" : "History Session")
        }
        
        let temporaryJob = ScheduledJob(
            id: UUID(),
            title: "\(record.title) (\(isZh ? "再次发送" : "Resend"))",
            prompt: record.prompt,
            model: model,
            reasoningEffort: effort,
            speed: .standard,
            destination: destination,
            strategy: .autoOnQuotaReset(safetyDelayMinutes: 0),
            dispatchMode: record.dispatchMode,
            status: .pending,
            createdAt: Date(),
            scheduledExecutionDate: Date()
        )
        
        queueManager.executeDirectJob(temporaryJob)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isResending = false
        }
    }
    
    private func loadIntoComposer() {
        let model = ModelCatalogService.shared.resolveModel(slugOrName: record.modelSlug)
        let effort: ReasoningEffort
        switch record.reasoningEffort {
        case "轻度", "low": effort = .low
        case "中", "medium": effort = .medium
        case "高", "high": effort = .high
        case "极高", "xhigh": effort = .xhigh
        case "Max", "max": effort = .max
        case "Ultra", "ultra": effort = .ultra
        default: effort = .low
        }
        
        var destination = TargetDestination()
        if let sId = record.targetSessionId, !sId.isEmpty {
            destination.conversationAction = .existing(id: sId, title: isZh ? "历史会话" : "History Session")
        }
        
        let job = ScheduledJob(
            id: UUID(),
            title: record.title,
            prompt: record.prompt,
            model: model,
            reasoningEffort: effort,
            speed: .standard,
            destination: destination,
            strategy: .dailyAtTime(hour: 7, minute: 0),
            dispatchMode: record.dispatchMode,
            status: .pending,
            createdAt: Date(),
            scheduledExecutionDate: nil
        )
        
        appState.openEditJobSheet(job: job)
    }
}
