import SwiftUI

struct TaskFlowView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTasks.keys.sorted(), id: \.self) { date in
                    Section(header: Text(dateFormatter.string(from: date))) {
                        ForEach(groupedTasks[date] ?? []) { task in
                            TaskFlowRow(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Поток задач")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var groupedTasks: [Date: [Task]] {
        let grouped = Dictionary(grouping: viewModel.tasks) { task in
            calendar.startOfDay(for: task.startTime)
        }
        return grouped
    }
}

struct TaskFlowRow: View {
    let task: Task
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                HStack {
                    Text(timeFormatter.string(from: task.startTime))
                    Text("-")
                    Text(timeFormatter.string(from: task.startTime.addingTimeInterval(task.duration)))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(task.category.color)
                .frame(width: 12, height: 12)
            
            Image(systemName: task.category.iconName)
                .foregroundColor(task.category.color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TaskFlowView(viewModel: ClockViewModel())
} 