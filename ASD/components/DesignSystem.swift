//
//  DesignSystem.swift
//  ASD
//
//  Shared visual building blocks used by every screen.
//

import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let subtleFill = Color(uiColor: .tertiarySystemFill)
}

// MARK: - Formatting

enum Format {
    static let locale = Locale(identifier: "uk_UA")

    static func milliseconds(_ ms: Double) -> String {
        if ms < 1 { return String(format: "%.4f мс", ms) }
        if ms < 1_000 { return String(format: "%.2f мс", ms) }
        return String(format: "%.2f с", ms / 1_000)
    }

    static func count(_ n: Int) -> String {
        n.formatted(.number.locale(locale))
    }

    static func compact(_ n: Int) -> String {
        n.formatted(.number.notation(.compactName).locale(locale))
    }

    static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

extension Duration {
    var milliseconds: Double {
        Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1e15
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Containers

struct Card<Content: View>: View {
    var title: String? = nil
    var systemImage: String? = nil
    var tint: Color = .accentColor
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(tint)
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground, in: .rect(cornerRadius: 22, style: .continuous))
    }
}

/// Common scaffold for a lab screen: header, scrolling content, pinned bottom action.
struct LabScreen<Content: View, Bar: View>: View {
    static var resultsAnchor: String { "results" }

    let lab: LabInfo
    /// Changes every time new results appear, so the screen scrolls to them.
    let scrollTrigger: Int
    @ViewBuilder var content: Content
    @ViewBuilder var bar: Bar

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    LabHeaderCard(lab: lab)
                    content
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.groupedBackground)
            .safeAreaInset(edge: .bottom) {
                bar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .onChange(of: scrollTrigger) {
                withAnimation(.snappy) {
                    proxy.scrollTo(Self.resultsAnchor, anchor: .top)
                }
            }
        }
        .navigationTitle("ЛР \(lab.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { hideKeyboard() }
            }
        }
    }
}

// MARK: - Lab header

struct LabHeaderCard: View {
    let lab: LabInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                IconTile(systemImage: lab.symbol, tint: lab.tint, size: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Лабораторна робота №\(lab.id)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(lab.tint)
                        .textCase(.uppercase)
                    Text(lab.title)
                        .font(.title3.bold())
                }
            }

            Text(lab.task)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let variant = lab.variant {
                    Pill(text: "Варіант \(variant)", systemImage: "number", tint: lab.tint)
                }
                if let complexity = lab.complexity {
                    Pill(text: complexity, systemImage: "speedometer", tint: .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: lab.symbol)
                        .font(.system(size: 110, weight: .bold))
                        .foregroundStyle(lab.tint.opacity(0.07))
                        .offset(x: 20, y: -10)
                }
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
        }
    }
}

// MARK: - Small components

struct IconTile: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: .rect(cornerRadius: size * 0.28, style: .continuous))
    }
}

struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: .capsule)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.1), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

struct SortedBadge: View {
    let isSorted: Bool
    var text: String? = nil

    var body: some View {
        let tint: Color = isSorted ? .green : .red
        Label(
            text ?? (isSorted ? "Результат упорядковано" : "Результат не впорядковано"),
            systemImage: isSorted ? "checkmark.seal.fill" : "xmark.octagon.fill"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 16, style: .continuous))
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct TruncationNote: View {
    let shown: Int
    let total: Int
    var unit: String = ""

    var body: some View {
        if total > shown {
            Text("Показано \(Format.count(shown)) з \(Format.count(total))\(unit.isEmpty ? "" : " \(unit)")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.6))
                .frame(width: 12, height: 12)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Inputs

struct NumberField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var presets: [Int] = []
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 12)
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: 130)
                    .background(Color.subtleFill, in: .capsule)
            }

            if !presets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            let isSelected = Int(text) == preset
                            Button {
                                text = String(preset)
                                hideKeyboard()
                            } label: {
                                Text(Format.compact(preset))
                                    .font(.footnote.weight(.semibold).monospacedDigit())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .background(isSelected ? tint : Color.subtleFill, in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: text)
            }
        }
    }
}

struct RunButton: View {
    var title: String = "Виконати"
    var systemImage: String = "play.fill"
    var tint: Color = .accentColor
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            hideKeyboard()
            withAnimation(.snappy) { action() }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
        .controlSize(.large)
        .disabled(isDisabled)
    }
}

// MARK: - Value chips

struct ValueChip: View {
    let text: String
    var tint: Color? = nil

    var body: some View {
        Text(text)
            .font(.callout.monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(tint ?? .primary)
            .background((tint ?? .secondary).opacity(tint == nil ? 0.1 : 0.16),
                        in: .rect(cornerRadius: 10, style: .continuous))
    }
}

/// Wraps children onto new lines like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            width = max(width, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
