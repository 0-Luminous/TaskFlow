import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: ClockViewModel
    @State private var selectedTask: Task?
    @State private var isEditingTask = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ClockViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var filteredTasks: [Date: [Task]] {
        let allTasks = searchText.isEmpty ? viewModel.tasks : viewModel.tasks.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        return Dictionary(grouping: allTasks) { task in
            Calendar.current.startOfDay(for: task.startTime)
        }
    }

    var sortedDates: [Date] {
        filteredTasks.keys.sorted()
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: viewModel.selectedDate) { newDate in
                        dismiss()
                    }
                
                List {
                    ForEach(sortedDates, id: \.self) { date in
                        if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
                            Section(header: Text(dateFormatter.string(from: date))) {
                                ForEach(filteredTasks[date]?.sorted(by: { $0.startTime < $1.startTime }) ?? []) { task in
                                    CalendarTaskRow(task: task, isSelected: selectedTask == task)
                                        .onTapGesture {
                                            selectedTask = task
                                            isEditingTask = true
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                selectedTask = task
                                                isEditingTask = true
                                            } label: {
                                                Label("Редактировать", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                                .onDelete { indexSet in
                                    deleteTask(at: indexSet, for: date)
                                }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        }
                    }
                }
                .animation(.default, value: viewModel.selectedDate)
            }
            .navigationTitle("Календарь")
            .searchable(text: $searchText, prompt: "Поиск задач")
            .sheet(isPresented: $isEditingTask) {
                if let task = selectedTask {
                    TaskEditorView(viewModel: viewModel, task: task, isPresented: $isEditingTask)
                }
            }
        }
    }

    private func deleteTask(at offsets: IndexSet, for date: Date) {
        guard let tasksForDate = filteredTasks[date] else { return }
        for index in offsets {
            let task = tasksForDate[index]
            viewModel.removeTask(task)
        }
    }
}

struct CalendarTaskRow: View {
    let task: Task
    let isSelected: Bool
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.category.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                HStack {
                    Text(timeFormatter.string(from: task.startTime))
                    Text("-")
                    Text(timeFormatter.string(from: task.startTime.addingTimeInterval(task.duration)))
                    Text("•")
                    Text(task.category.rawValue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: task.category.iconName)
                .foregroundColor(task.category.color)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        CalendarView(viewModel: ClockViewModel())
    }
}
