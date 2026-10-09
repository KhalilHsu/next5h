import SwiftUI
import AppKit

public struct HistoryListView: View {
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    @State private var filterSelection: HistoryFilter = .all
    
    public init() {}
    
    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "all"
        case success = "success"
        case failure = "failure"
        
        public var id: String { rawValue }
        
        public var label: String {
            switch self {
            case .all: return L10n.tr(zh: "全部", en: "All", ja: "すべて")
            case .success: return L10n.tr(zh: "成功", en: "Success", ja: "成功")
            case .failure: return L10n.tr(zh: "失败", en: "Failure", ja: "失敗")
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
        guard !historyManager.records.isEmpty else { return "—" }
        let successCount = historyManager.records.filter { $0.isSuccess }.count
        let rate = Double(successCount) / Double(historyManager.records.count) * 100.0
        return "\(Int(rate))%"
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(L10n.historyTitle)
                                .font(.system(size: 21, weight: .semibold))

                            if !historyManager.records.isEmpty {
                                Text(L10n.historyTotalCount(historyManager.records.count))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if historyManager.records.isEmpty {
                            Text(L10n.historySubtitle)
                                .font(.caption)
                                .foregroundStyle(Next5hTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            (Text(L10n.historyTodaySuccess + " ")
                             + Text("\(historyManager.todaySuccessCount)" + L10n.tr(zh: " 次", en: "", ja: " 件"))
                                .fontWeight(.medium)
                             + Text("  ·  " + L10n.historySuccessRate + " ")
                             + Text(successRateText).fontWeight(.medium))
                                .font(.caption)
                                .foregroundStyle(Next5hTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 0)

                    Next5hSegmentedControl(
                        label: L10n.tr(zh: "结果筛选", en: "Result filter", ja: "結果フィルター"),
                        selection: $filterSelection,
                        options: HistoryFilter.allCases.map { .init(value: $0, title: $0.label) }
                    )
                    .frame(width: 180)
                }
                .padding(.top, 24)
                .padding(.bottom, 10)

                // 历史流水列表 (使用 LazyVStack 保证与上方所有文字/指标 100% 像素级对齐)
                if filteredRecords.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 36)
                        Image(systemName: historyManager.records.isEmpty ? "clock.arrow.circlepath" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.tertiary)
                        
                        Text(historyManager.records.isEmpty ? L10n.historyEmptyTitle : L10n.tr(zh: "当前筛选条件下无记录", en: "No records for this filter", ja: "該当する履歴はありません"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(historyManager.records.isEmpty ? L10n.historyEmptySubtitle : L10n.tr(zh: "您可以切换筛选器查看全部记录。", en: "You can switch filters to view all records.", ja: "フィルターを切り替えてすべての履歴を確認できます。"))
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
    
    private func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "\(L10n.tr(zh: "今天", en: "Today", ja: "今日")) HH:mm:ss"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "\(L10n.tr(zh: "昨天", en: "Yesterday", ja: "昨日")) HH:mm:ss"
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
                    .foregroundStyle(record.isSuccess ? Next5hTheme.mint : .red)
                
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
                    .background(Capsule().fill(Next5hTheme.accent.opacity(0.08)))
                    .foregroundStyle(Next5hTheme.secondary)
                
                Text(L10n.tr(zh: "推理: \(record.reasoningEffort)", en: "Effort: \(record.reasoningEffort)", ja: "推論: \(record.reasoningEffort)"))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    .foregroundStyle(.secondary)
                
                Text(record.dispatchMode == .silentAPI
                     ? L10n.tr(zh: "静默 CLI", en: "Silent CLI", ja: "サイレント CLI")
                     : L10n.tr(zh: "前台 GUI", en: "Foreground GUI", ja: "前面 GUI"))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Next5hTheme.subtle))
                    .foregroundStyle(Next5hTheme.secondary)
                
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
                    Text(L10n.tr(
                        zh: "• 会话: \(sessionId.prefix(8))...",
                        en: "• Session: \(sessionId.prefix(8))...",
                        ja: "• セッション: \(sessionId.prefix(8))..."
                    ))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            // Prompt 内容预览区
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.tr(zh: "User Query 内容:", en: "User Query Content:", ja: "プロンプト内容:"))
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
                        Next5hButtonLabel(
                            hasCopied
                                ? L10n.tr(zh: "已复制", en: "Copied", ja: "コピー完了")
                                : L10n.tr(zh: "复制", en: "Copy", ja: "コピー"),
                            systemImage: hasCopied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(Next5hButtonStyle(kind: .quiet))
                }
                
                Text(record.prompt)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Next5hTheme.subtle))
            }
            
            // 若失败，展示错误信息提示条
            if !record.isSuccess, let err = record.errorMessage, !err.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(L10n.tr(zh: "错误详情: \(err)", en: "Error: \(err)", ja: "エラー詳細: \(err)"))
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
            HStack(spacing: Next5hButtonMetrics.groupSpacing) {
                // 1. 再次发送
                Button {
                    resendJob()
                } label: {
                    Next5hButtonLabel(L10n.tr(zh: "再次发送", en: "Resend", ja: "再送信"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(Next5hButtonStyle(kind: .quiet))
                .disabled(isResending)
                
                // 2. 以此历史记录为模板新建任务 (直接唤起 Sheet)
                Button {
                    loadIntoComposer()
                } label: {
                    Next5hButtonLabel(L10n.tr(zh: "以此为模板新建", en: "Use as Template", ja: "テンプレートとして利用"), systemImage: "doc.badge.plus")
                }
                .buttonStyle(Next5hButtonStyle(kind: .quiet))
                
                // 3. 在 Codex 中打开会话
                if let sessionId = record.targetSessionId, !sessionId.isEmpty {
                    Button {
                        if let url = URL(string: "codex://threads/\(sessionId)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Next5hButtonLabel(L10n.tr(zh: "在 Codex 中打开", en: "Open in Codex", ja: "Codex で開く"), systemImage: "bubble.left.and.bubble.right")
                    }
                    .buttonStyle(Next5hButtonStyle(kind: .quiet))
                }
                
                Spacer()
                
                // 4. 删除单条记录
                Button(role: .destructive) {
                    historyManager.deleteRecord(id: record.id)
                } label: {
                    Next5hButtonLabel(systemImage: "trash")
                }
                .buttonStyle(Next5hButtonStyle(kind: .quiet, iconOnly: true))
                .help(L10n.tr(zh: "删除记录", en: "Delete record", ja: "履歴を削除"))
            }
        }
        .next5hSurface(padding: 18)
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
            destination.conversationAction = .existing(
                id: sId,
                title: L10n.tr(zh: "历史会话", en: "History Session", ja: "既存セッション")
            )
        }
        
        let temporaryJob = ScheduledJob(
            id: UUID(),
            title: "\(record.title) (\(L10n.tr(zh: "再次发送", en: "Resend", ja: "再送信")))",
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
            destination.conversationAction = .existing(
                id: sId,
                title: L10n.tr(zh: "历史会话", en: "History Session", ja: "既存セッション")
            )
        }
        
        let job = ScheduledJob(
            id: UUID(),
            title: record.title,
            prompt: record.prompt,
            model: model,
            reasoningEffort: effort,
            speed: .standard,
            destination: destination,
            strategy: record.templateStrategy(sourceJob: queueManager.jobs.first { $0.id == record.jobId }),
            dispatchMode: record.dispatchMode,
            status: .pending,
            createdAt: Date(),
            scheduledExecutionDate: nil
        )
        
        appState.openEditJobSheet(job: job)
    }
}
