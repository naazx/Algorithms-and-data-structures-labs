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
    static let hairline = Color(uiColor: .separator).opacity(0.35)
}

// MARK: - Surfaces

extension View {
    /// Standard raised surface for cards: background, hairline border and a soft shadow.
    func cardSurface(cornerRadius: CGFloat = 22) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.cardBackground)
                .strokeBorder(Color.hairline, lineWidth: 0.5)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
    }
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
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(tint)
                            .frame(width: 28, height: 28)
                            .background(tint.opacity(0.14), in: .rect(cornerRadius: 8, style: .continuous))
                    }
                    Text(title)
                        .font(.headline)
                }
                .padding(.bottom, 2)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
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
                Image(systemName: lab.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(lab.tint)
                    .frame(width: 54, height: 54)
                    .background(.white, in: .rect(cornerRadius: 15, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Лабораторна робота №\(lab.id)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .textCase(.uppercase)
                    Text(lab.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
            }

            Text(lab.task)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let variant = lab.variant {
                    Pill(text: "Варіант \(variant)", systemImage: "number", tint: .white)
                }
                if let complexity = lab.complexity {
                    Pill(text: complexity, systemImage: "speedometer", tint: .white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(lab.tint.gradient)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: lab.symbol)
                        .font(.system(size: 130, weight: .bold))
                        .foregroundStyle(.white.opacity(0.12))
                        .rotationEffect(.degrees(-12))
                        .offset(x: 30, y: -16)
                }
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
                .shadow(color: lab.tint.opacity(0.3), radius: 14, y: 6)
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
        .background(tint.opacity(0.16), in: .capsule)
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
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(tint.gradient, in: .circle)
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
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.1))
                .strokeBorder(tint.opacity(0.18), lineWidth: 0.5)
        }
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
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
                .strokeBorder(tint.opacity(0.25), lineWidth: 0.5)
        }
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
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.1))
                    .strokeBorder(Color.red.opacity(0.25), lineWidth: 0.5)
            }
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

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
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
