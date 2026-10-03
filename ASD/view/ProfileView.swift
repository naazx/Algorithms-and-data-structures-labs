//
//  ProfileView.swift
//  ASD
//

import SwiftUI
import Charts

struct ProfileView: View {
    @Environment(StatsStore.self) private var stats
    @AppStorage("profile.name") private var name = "Назар Дидин"
    @AppStorage("profile.group") private var group = ""

    @State private var isEditing = false
    @State private var isConfirmingReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    progressCard
                    statsGrid
                    activityCard
                    labsChartCard
                    recordsCard
                    recentCard
                }
                .padding(16)
            }
            .background(Color.groupedBackground)
            .navigationTitle("Профіль")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Редагувати профіль", systemImage: "pencil") {
                            isEditing = true
                        }
                        Button("Скинути статистику", systemImage: "trash", role: .destructive) {
                            isConfirmingReset = true
                        }
                        .disabled(stats.runs.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                ProfileEditor(name: $name, group: $group)
            }
            .confirmationDialog("Скинути всю статистику?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
                Button("Скинути", role: .destructive) {
                    withAnimation { stats.reset() }
                }
            } message: {
                Text("Історію запусків буде видалено без можливості відновлення.")
            }
        }
    }

    // MARK: - Header

    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(initials)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(
                    LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .circle
                )
                .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)

            Text(name.isEmpty ? "Студент" : name)
                .font(.title2.bold())

            Button {
                isEditing = true
            } label: {
                Text(group.isEmpty ? "Додати групу" : group)
                    .font(.subheadline)
                    .foregroundStyle(group.isEmpty ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            Pill(text: "Алгоритми та структури даних", systemImage: "graduationcap.fill", tint: .indigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Progress

    private var progressCard: some View {
        let done = LabCatalog.available.count
        let total = LabCatalog.all.count
        let explored = stats.exploredLabs

        return Card {
            HStack(spacing: 20) {
                ProgressRing(progress: Double(done) / Double(total), tint: .indigo) {
                    VStack(spacing: 0) {
                        Text("\(done)")
                            .font(.title.bold().monospacedDigit())
                        Text("з \(total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Прогрес курсу")
                        .font(.headline)
                    progressLine(title: "Виконано робіт", value: "\(done) / \(total)", tint: .indigo)
                    progressLine(title: "Запущено в застосунку", value: "\(explored) / \(done)", tint: .teal)
                }
            }
        }
    }

    private func progressLine(title: String, value: String, tint: Color) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "Запусків", value: Format.count(stats.runs.count),
                       systemImage: "play.circle.fill", tint: .blue)
            MetricTile(title: "Відсортовано елементів", value: Format.compact(stats.totalElements),
                       systemImage: "square.stack.3d.up.fill", tint: .purple)
            MetricTile(title: stats.streak == 1 ? "День поспіль" : "Днів поспіль", value: "\(stats.streak)",
                       systemImage: "flame.fill", tint: .orange)
            MetricTile(title: "Коректних результатів",
                       value: stats.correctnessRate.map { "\(Int(($0 * 100).rounded()))%" } ?? "—",
                       systemImage: "checkmark.seal.fill", tint: .green)
        }
    }

    // MARK: - Charts

    private var activityCard: some View {
        Card(title: "Активність за тиждень", systemImage: "calendar", tint: .blue) {
            Chart(stats.dailyActivity()) { day in
                BarMark(
                    x: .value("День", day.day, unit: .day),
                    y: .value("Запуски", day.count)
                )
                .foregroundStyle(Calendar.current.isDateInToday(day.day) ? Color.blue.gradient : Color.blue.opacity(0.45).gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
        }
    }

    @ViewBuilder
    private var labsChartCard: some View {
        let labs = LabCatalog.available

        Card(title: "Запуски за лабораторними", systemImage: "chart.bar.fill", tint: .purple) {
            if stats.runs.isEmpty {
                emptyHint
            } else {
                Chart(labs) { lab in
                    BarMark(
                        x: .value("Запуски", stats.runCount(for: lab.id)),
                        y: .value("Лабораторна", "ЛР \(lab.id)")
                    )
                    .foregroundStyle(lab.tint.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(stats.runCount(for: lab.id))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(labs.count) * 34)
            }
        }
    }

    // MARK: - Lists

    @ViewBuilder
    private var recordsCard: some View {
        let records = LabCatalog.available.compactMap { lab in
            stats.largestRun(for: lab.id).map { (lab, $0) }
        }

        if !records.isEmpty {
            Card(title: "Найбільші запуски", systemImage: "trophy.fill", tint: .yellow) {
                VStack(spacing: 12) {
                    ForEach(records, id: \.0.id) { lab, run in
                        HStack(spacing: 12) {
                            IconTile(systemImage: lab.symbol, tint: lab.tint, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lab.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(Format.count(run.elements)) елементів")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let ms = run.milliseconds {
                                Text(Format.milliseconds(ms))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentCard: some View {
        Card(title: "Останні запуски", systemImage: "clock.arrow.circlepath", tint: .teal) {
            if stats.runs.isEmpty {
                emptyHint
            } else {
                VStack(spacing: 12) {
                    ForEach(stats.runs.suffix(6).reversed()) { run in
                        let lab = LabCatalog.lab(run.lab)
                        HStack(spacing: 12) {
                            IconTile(systemImage: lab.symbol, tint: lab.tint, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ЛР \(lab.id) · \(lab.title)")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(run.date, format: .relative(presentation: .named))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Format.compact(run.elements))
                                    .font(.subheadline.monospacedDigit())
                                if let sorted = run.isSorted {
                                    Image(systemName: sorted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(sorted ? .green : .red)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyHint: some View {
        Label("Запусти будь-яку лабораторну, і тут з'явиться статистика.", systemImage: "sparkles")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }
}

// MARK: - Helpers

private struct ProgressRing<Label: View>: View {
    let progress: Double
    let tint: Color
    @ViewBuilder var label: Label

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
    }
}

private struct ProfileEditor: View {
    @Binding var name: String
    @Binding var group: String

    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftGroup = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Ім'я") {
                    TextField("Прізвище та ім'я", text: $draftName)
                        .textContentType(.name)
                }
                Section("Група") {
                    TextField("Напр. КН-21", text: $draftGroup)
                }
            }
            .navigationTitle("Профіль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        name = draftName.trimmingCharacters(in: .whitespaces)
                        group = draftGroup.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                }
            }
            .onAppear {
                draftName = name
                draftGroup = group
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProfileView()
        .environment(StatsStore())
}
