import SwiftUI

struct TodayTasksView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(selectedDateTasks) { task in
                    TaskRow(task: task, isSelected: task.isCompleted)
                        .onTapGesture {
                            toggleTaskCompletion(task)
                        }
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle(navigationTitle)
            .sheet(isPresented: $showingAddTask) {
                TaskEditorView(viewModel: viewModel, 
                             task: Task(id: UUID(), 
                                      title: "", 
                                      startTime: viewModel.selectedDate, 
                                      duration: 3600, 
                                      color: .blue, 
                                      icon: "circle", 
                                      category: .work), 
                             isPresented: $showingAddTask)
            }
        }
    }
    
    private var selectedDateTasks: [Task] {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: viewModel.selectedDate)
        return viewModel.tasks
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDay) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private var navigationTitle: String {
        if Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()) {
            return "Сегодня"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: viewModel.selectedDate)
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = selectedDateTasks[index]
            viewModel.removeTask(task)
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        viewModel.updateTask(updatedTask)
    }
}

struct TodayTasksView_Previews: PreviewProvider {
    static var previews: some View {
        TodayTasksView(viewModel: ClockViewModel())
    }
}
