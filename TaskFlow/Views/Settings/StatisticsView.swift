import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case day = "День"
        case week = "Неделя"
        case month = "Месяц"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Период", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical)
                }
                
                Section(header: Text("Распределение по категориям")) {
                    if #available(iOS 16.0, *) {
                        Chart(categoryData) { item in
                            SectorMark(
                                angle: .value("Время", item.duration),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(item.category.color)
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    
                    ForEach(categoryData) { item in
                        HStack {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 20, height: 20)
                            Text(item.category.rawValue)
                            Spacer()
                            Text(formatDuration(item.duration))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Общая статистика")) {
                    StatRow(title: "Всего задач", value: "\(filteredTasks.count)")
                    StatRow(title: "Выполнено", value: "\(completedTasks.count)")
                    StatRow(title: "Общее время", value: formatDuration(totalDuration))
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }
        
        return viewModel.tasks.filter { $0.startTime >= startDate }
    }
    
    private var completedTasks: [Task] {
        filteredTasks.filter { $0.isCompleted }
    }
    
    private var totalDuration: TimeInterval {
        filteredTasks.reduce(0) { $0 + $1.duration }
    }
    
    private var categoryData: [CategoryData] {
        let tasksByCategory = Dictionary(grouping: filteredTasks, by: { $0.category })
        return tasksByCategory.map { category, tasks in
            CategoryData(
                category: category,
                duration: tasks.reduce(0) { $0 + $1.duration }
            )
        }
        .sorted { $0.duration > $1.duration }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return "\(hours)ч \(minutes)м"
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: TaskCategoryModel
    let duration: TimeInterval
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatisticsView(viewModel: ClockViewModel())
}
