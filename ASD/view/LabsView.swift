//
//  LabsView.swift
//  ASD
//

import SwiftUI

struct LabsView: View {
    @Environment(StatsStore.self) private var stats
    @State private var query = ""

    private var filteredLabs: [LabInfo] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return LabCatalog.all }
        return LabCatalog.all.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.task.localizedCaseInsensitiveContains(trimmed)
                || String($0.id) == trimmed
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if query.isEmpty {
                        progressCard
                            .padding(.bottom, 4)
                    }

                    ForEach(filteredLabs) { lab in
                        if lab.isAvailable {
                            NavigationLink(value: lab) {
                                LabCard(lab: lab,
                                        runCount: stats.runCount(for: lab.id),
                                        lastRun: stats.lastRun(for: lab.id))
                            }
                            .buttonStyle(.plain)
                        } else {
                            LabCard(lab: lab, runCount: 0, lastRun: nil)
                        }
                    }

                    if filteredLabs.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
                .padding(16)
            }
            .background(Color.groupedBackground)
            .navigationTitle("Лабораторні")
            .searchable(text: $query, prompt: "Назва, алгоритм або номер")
            .navigationDestination(for: LabInfo.self) { lab in
                LabDestination(lab: lab)
            }
        }
    }

    private var progressCard: some View {
        let done = LabCatalog.available.count
        let total = LabCatalog.all.count
        let next = LabCatalog.all.first { !$0.isAvailable }

        return VStack(alignment: .leading, spacing: 12) {
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

            ProgressView(value: Double(done), total: Double(total))
                .tint(.white)

            if let next {
                Label("Далі: лабораторна робота №\(next.id)", systemImage: "arrow.forward.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 24, style: .continuous)
        )
    }
}

private struct LabCard: View {
    let lab: LabInfo
    let runCount: Int
    let lastRun: LabRun?

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemImage: lab.symbol, tint: lab.tint, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("ЛР \(lab.id)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(lab.isAvailable ? lab.tint : .secondary)
                    if let variant = lab.variant {
                        Text("· Варіант \(variant)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(lab.isAvailable ? lab.title : "Скоро")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(lab.task)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if lab.isAvailable {
                    HStack(spacing: 12) {
                        if let complexity = lab.complexity {
                            Label(complexity, systemImage: "speedometer")
                        }
                        if runCount > 0 {
                            Label("\(runCount)", systemImage: "play.circle")
                        }
                        if let lastRun {
                            Label {
                                Text(lastRun.date, format: .relative(presentation: .named))
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: lab.isAvailable ? "chevron.right" : "lock.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.cardBackground, in: .rect(cornerRadius: 22, style: .continuous))
        .opacity(lab.isAvailable ? 1 : 0.6)
        .contentShape(.rect(cornerRadius: 22))
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
        default: ContentUnavailableView("Скоро", systemImage: "lock.fill")
        }
    }
}

#Preview {
    LabsView()
        .environment(StatsStore())
}
