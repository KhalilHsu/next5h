import SwiftUI
import AppKit

enum Next5hButtonMetrics {
    static let font = Font.system(size: 13, weight: .medium)
    static let iconFont = Font.system(size: 14, weight: .regular)
    static let height: CGFloat = 32
    static let iconSize: CGFloat = 14
    static let iconWidth: CGFloat = 16
    static let labelSpacing: CGFloat = 6
    static let groupSpacing: CGFloat = 4
}

struct Next5hButtonLabel: View {
    let title: String?
    let symbol: String

    init(_ title: String? = nil, systemImage: String) {
        self.title = title
        self.symbol = systemImage
    }

    var body: some View {
        HStack(spacing: Next5hButtonMetrics.labelSpacing) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .font(Next5hButtonMetrics.iconFont)
                .frame(width: Next5hButtonMetrics.iconSize, height: Next5hButtonMetrics.iconSize)
                .frame(width: Next5hButtonMetrics.iconWidth, height: Next5hButtonMetrics.iconWidth)
            if let title {
                Text(title)
                    .font(Next5hButtonMetrics.font)
                    .lineLimit(1)
            }
        }
    }
}

struct Next5hButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet }
    var kind: Kind = .secondary
    var iconOnly = false
    var selected = false

    func makeBody(configuration: Configuration) -> some View {
        ButtonBody(configuration: configuration, kind: kind, iconOnly: iconOnly, selected: selected)
    }

    private struct ButtonBody: View {
        let configuration: ButtonStyle.Configuration
        let kind: Kind
        let iconOnly: Bool
        let selected: Bool
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var hovered = false

        var body: some View {
            configuration.label
                .font(Next5hButtonMetrics.font)
                .padding(.horizontal, iconOnly ? 0 : 12)
                .frame(width: iconOnly ? Next5hButtonMetrics.height : nil, height: Next5hButtonMetrics.height)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(kind == .secondary ? Next5hTheme.border : .clear, lineWidth: 1))
                .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
        }

        private var foreground: Color {
            if kind == .primary { return Next5hTheme.onAccent }
            if isEnabled && hovered && configuration.role == .destructive { return .red }
            if selected { return Next5hTheme.accent }
            return Next5hTheme.ink
        }

        private var background: Color {
            let active = isEnabled && (hovered || configuration.isPressed)
            if active && configuration.role == .destructive { return .red.opacity(0.09) }
            switch kind {
            case .primary: return active ? Next5hTheme.accentHover : Next5hTheme.accent
            case .secondary: return active ? Next5hTheme.hover : Next5hTheme.surface
            case .quiet:
                if selected { return Next5hTheme.accent.opacity(active ? 0.16 : 0.10) }
                return active ? Next5hTheme.hover : .clear
            }
        }
    }
}

struct Next5hChoice<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    var id: Value { value }
}

/// A flat selection control; actions write through the existing binding.
struct Next5hSegmentedControl<Value: Hashable>: View {
    let label: String
    @Binding var selection: Value
    let options: [Next5hChoice<Value>]
    @FocusState private var focusedValue: Value?
    @State private var hoveredValue: Value?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options) { option in
                Button {
                    selection = option.value
                    focusedValue = option.value
                } label: {
                    Text(option.title)
                        .font(.system(size: 12, weight: selection == option.value ? .semibold : .regular))
                        .foregroundStyle(selection == option.value ? Next5hTheme.accent : Next5hTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(selection == option.value ? Next5hTheme.surface : (hoveredValue == option.value ? Next5hTheme.hover : .clear),
                                    in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(focusedValue == option.value ? Next5hTheme.accent : (selection == option.value ? Next5hTheme.border : .clear), lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable()
                .focusEffectDisabled()
                .focused($focusedValue, equals: option.value)
                .onHover { hoveredValue = $0 ? option.value : nil }
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selection == option.value ? .isSelected : [])
                .onKeyPress(.leftArrow) { move(from: selection, offset: -1); return .handled }
                .onKeyPress(.rightArrow) { move(from: selection, offset: 1); return .handled }
            }
        }
        .padding(3)
        .background(Next5hTheme.subtle, in: RoundedRectangle(cornerRadius: 9))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func move(from value: Value, offset: Int) {
        guard let index = options.firstIndex(where: { $0.value == value }) else { return }
        let next = max(0, min(options.count - 1, index + offset))
        selection = options[next].value
        focusedValue = selection
    }
}

/// Keep the system menu's keyboard navigation and scrolling, with a flat trigger.
struct Next5hMenuPicker<Value: Hashable>: View {
    let label: String
    @Binding var selection: Value
    let options: [Next5hChoice<Value>]
    @State private var hovered = false
    @State private var focused = false
    @Environment(\.isEnabled) private var isEnabled

    private var selectedTitle: String {
        options.first(where: { $0.value == selection })?.title ?? label
    }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                Text(selectedTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Next5hTheme.secondary)
            }
            .font(.system(size: 13))
            .foregroundStyle(Next5hTheme.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovered ? Next5hTheme.subtle : Next5hTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(focused ? Next5hTheme.accent : (hovered ? Next5hTheme.secondary.opacity(0.5) : Next5hTheme.border), lineWidth: 1))
            .contentShape(Rectangle())
            .accessibilityHidden(true)

            NativeMenu(selection: $selection, options: options, label: label,
                       enabled: isEnabled && !options.isEmpty, focused: $focused)
        }
        .onHover { hovered = $0 }
        .help(selectedTitle)
    }

    static func makeMenu(titles: [String]) -> NSMenu {
        let menu = NSMenu()
        for title in titles {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.toolTip = title
            menu.addItem(item)
        }
        return menu
    }

    private struct NativeMenu: NSViewRepresentable {
        @Binding var selection: Value
        let options: [Next5hChoice<Value>]
        let label: String
        let enabled: Bool
        @Binding var focused: Bool

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeNSView(context: Context) -> MenuControl {
            let control = MenuControl(frame: .zero, pullsDown: false)
            control.isBordered = false
            control.focusRingType = .none
            control.target = context.coordinator
            control.action = #selector(Coordinator.changed(_:))
            control.onFocusChange = { context.coordinator.parent.focused = $0 }
            control.setContentHuggingPriority(.defaultLow, for: .horizontal)
            return control
        }

        func updateNSView(_ control: MenuControl, context: Context) {
            context.coordinator.parent = self
            let titles = options.map(\.title)
            if control.itemTitles != titles {
                // NSPopUpButton.addItems deduplicates titles; distinct sessions
                // can share a title, so construct the menu items individually.
                control.menu = Next5hMenuPicker.makeMenu(titles: titles)
            }
            if let index = options.firstIndex(where: { $0.value == selection }) {
                control.selectItem(at: index)
            }
            control.isEnabled = enabled
            control.setAccessibilityLabel(label)
        }

        final class Coordinator: NSObject {
            var parent: NativeMenu
            init(_ parent: NativeMenu) { self.parent = parent }

            @objc func changed(_ control: NSPopUpButton) {
                let index = control.indexOfSelectedItem
                guard parent.options.indices.contains(index) else { return }
                parent.selection = parent.options[index].value
            }
        }

        // SwiftUI draws the trigger; AppKit retains menu, type-ahead and Tab behavior.
        final class MenuControl: NSPopUpButton {
            var onFocusChange: ((Bool) -> Void)?
            override func draw(_ dirtyRect: NSRect) {}

            override func becomeFirstResponder() -> Bool {
                let accepted = super.becomeFirstResponder()
                if accepted { onFocusChange?(true) }
                return accepted
            }

            override func resignFirstResponder() -> Bool {
                let accepted = super.resignFirstResponder()
                if accepted { onFocusChange?(false) }
                return accepted
            }
        }
    }
}

/// Native editable date segments without the legacy bezel and spinner.
struct Next5hDateField: View {
    let label: String
    @Binding var selection: Date
    var includesDate = false
    @State private var hovered = false
    @State private var focused = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: includesDate ? "calendar" : "clock")
                .font(.system(size: 12))
                .foregroundStyle(Next5hTheme.secondary)
            DateInput(label: label, selection: $selection, includesDate: includesDate, focused: $focused)
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Next5hTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(focused ? Next5hTheme.accent : (hovered ? Next5hTheme.secondary.opacity(0.5) : Next5hTheme.border), lineWidth: 1))
        .onHover { hovered = $0 }
    }

    private struct DateInput: NSViewRepresentable {
        let label: String
        @Binding var selection: Date
        let includesDate: Bool
        @Binding var focused: Bool

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeNSView(context: Context) -> DateControl {
            let picker = DateControl()
            picker.datePickerStyle = .textField
            picker.datePickerMode = .single
            picker.datePickerElements = includesDate ? [.yearMonthDay, .hourMinute] : [.hourMinute]
            picker.presentsCalendarOverlay = includesDate
            picker.isBezeled = false
            picker.isBordered = false
            picker.drawsBackground = false
            picker.focusRingType = .none
            picker.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            picker.target = context.coordinator
            picker.action = #selector(Coordinator.changed(_:))
            picker.onFocusChange = { context.coordinator.parent.focused = $0 }
            return picker
        }

        func updateNSView(_ picker: DateControl, context: Context) {
            context.coordinator.parent = self
            if picker.dateValue != selection { picker.dateValue = selection }
            picker.textColor = NSColor(Next5hTheme.ink)
            picker.setAccessibilityLabel(label)
        }

        func sizeThatFits(_ proposal: ProposedViewSize, nsView: DateControl, context: Context) -> CGSize? {
            // Include locale-specific fields such as AM/PM without clipping.
            CGSize(width: max(includesDate ? 166 : 51, nsView.cell?.cellSize.width ?? 0), height: 22)
        }

        final class Coordinator: NSObject {
            var parent: DateInput
            init(_ parent: DateInput) { self.parent = parent }

            @objc func changed(_ picker: NSDatePicker) {
                parent.selection = picker.dateValue
            }
        }

        final class DateControl: NSDatePicker {
            var onFocusChange: ((Bool) -> Void)?

            override func becomeFirstResponder() -> Bool {
                let accepted = super.becomeFirstResponder()
                if accepted { onFocusChange?(true) }
                return accepted
            }

            override func resignFirstResponder() -> Bool {
                let accepted = super.resignFirstResponder()
                if accepted { onFocusChange?(false) }
                return accepted
            }
        }
    }
}

struct Next5hSectionHeading: View {
    let title: String
    let symbol: String
    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Next5hTheme.ink)
    }
}
