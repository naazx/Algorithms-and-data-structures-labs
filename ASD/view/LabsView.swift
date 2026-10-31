//
//  LabsView.swift
//  ASD
//

import SwiftUI

private enum LabFilter: String, CaseIterable, Identifiable {
    case all = "Усі"
    case started = "Запущені"
    case notStarted = "Нові"

    var id: Self { self }
}

struct LabsView: View {
    @Environment(StatsStore.self) private var stats
    @State private var query = ""
    @State private var filter: LabFilter = .all
    @State private var path: [LabInfo] = []

    private var filteredLabs: [LabInfo] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return LabCatalog.available.filter { lab in
            switch filter {
            case .all: true
            case .started: stats.runCount(for: lab.id) > 0
            case .notStarted: stats.runCount(for: lab.id) == 0
            }
        }
        .filter {
            trimmed.isEmpty
                || $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.task.localizedCaseInsensitiveContains(trimmed)
                || String($0.id) == trimmed
        }
    }

    private var upcomingLabs: [LabInfo] {
        query.isEmpty && filter == .all ? LabCatalog.all.filter { !$0.isAvailable } : []
    }

    private var continueLab: LabInfo? {
        stats.runs.last.map { LabCatalog.lab($0.lab) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if query.isEmpty {
                        progressCard
                            .padding(.bottom, 4)
                    }

                    filterBar

                    ForEach(filteredLabs) { lab in
                        NavigationLink(value: lab) {
                            LabCard(lab: lab,
                                    runCount: stats.runCount(for: lab.id),
                                    lastRun: stats.lastRun(for: lab.id))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    if filteredLabs.isEmpty {
                        if query.isEmpty {
                            ContentUnavailableView("Тут поки порожньо",
                                                   systemImage: "tray",
                                                   description: Text("Немає лабораторних для фільтра «\(filter.rawValue)»."))
                        } else {
                            ContentUnavailableView.search(text: query)
                        }
                    }

                    if !upcomingLabs.isEmpty {
                        SectionHeader(title: "Незабаром", subtitle: "\(upcomingLabs.count)")
                        ForEach(upcomingLabs) { lab in
                            UpcomingLabRow(lab: lab)
                        }
                    }
                }
                .padding(16)
                .animation(.snappy, value: filter)
            }
            .background(Color.groupedBackground)
            .navigationTitle("Лабораторні")
            .searchable(text: $query, prompt: "Назва, алгоритм або номер")
            .navigationDestination(for: LabInfo.self) { lab in
                LabDestination(lab: lab)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(LabFilter.allCases) { option in
                let isSelected = filter == option
                Button {
                    filter = option
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? Color.white : .primary)
                        .background {
                            Capsule()
                                .fill(isSelected ? AnyShapeStyle(Color.indigo.gradient) : AnyShapeStyle(Color.cardBackground))
                                .strokeBorder(isSelected ? .clear : Color.hairline, lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .sensoryFeedback(.selection, trigger: filter)
    }

    private var progressCard: some View {
        let done = LabCatalog.available.count
        let total = LabCatalog.all.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Алгоритми та структури даних")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Виконано \(done) з \(total)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("\(Int(Double(done) / Double(total) * 100))%")
                    .font(.title.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }

            HStack(spacing: 5) {
                ForEach(LabCatalog.all) { lab in
                    Capsule()
                        .fill(.white.opacity(lab.isAvailable ? 1 : 0.25))
                        .frame(height: 6)
                }
            }

            if let lab = continueLab {
                Button {
                    path = [lab]
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: lab.symbol)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(lab.tint)
                            .frame(width: 30, height: 30)
                            .background(.white, in: .rect(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Продовжити")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("ЛР \(lab.id) · \(lab.title)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .background(.white.opacity(0.16), in: .rect(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            } else if let next = LabCatalog.all.first(where: { !$0.isAvailable }) {
                Label("Далі: лабораторна робота №\(next.id)", systemImage: "arrow.forward.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [.indigo, .purple, .pink.opacity(0.85)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "function")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundStyle(.white.opacity(0.08))
                        .offset(x: 24, y: -20)
                }
                .clipShape(.rect(cornerRadius: 26, style: .continuous))
                .shadow(color: .purple.opacity(0.3), radius: 16, y: 8)
        }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

private struct LabCard: View {
    let lab: LabInfo
    let runCount: Int
    let lastRun: LabRun?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(systemImage: lab.symbol, tint: lab.tint, size: 46)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ЛР \(lab.id)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(lab.tint)
                        if let variant = lab.variant {
                            Text("· Варіант \(variant)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(lab.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text(lab.task)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                if let complexity = lab.complexity {
                    Pill(text: complexity, systemImage: "speedometer", tint: lab.tint)
                }
                if runCount > 0 {
                    Pill(text: "\(runCount)", systemImage: "play.fill", tint: .secondary)
                }
                Spacer(minLength: 0)
                if let lastRun {
                    Text(lastRun.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Нова")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .lineLimit(1)
        }
        .padding(14)
        .cardSurface()
        .contentShape(.rect(cornerRadius: 22))
    }
}

private struct UpcomingLabRow: View {
    let lab: LabInfo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color.subtleFill, in: .rect(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("ЛР \(lab.id)")
                    .font(.subheadline.weight(.semibold))
                Text(lab.task)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.hairline, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }
    }
}

private struct LabDestination: View {
    let lab: LabInfo

    var body: some View {
        switch lab.id {
        case 1: Lab1View()
        case 2: Lab2View()
        case 3: Lab3View()
        case 4: Lab4View()
        case 5: Lab5View()
        case 6: Lab6View()
        case 7: Lab7View()
        case 8: Lab8View()
        default: ContentUnavailableView("Скоро", systemImage: "lock.fill")
        }
    }
}

#Preview {
    LabsView()
        .environment(StatsStore())
}
