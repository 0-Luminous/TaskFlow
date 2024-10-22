import SwiftUI

struct TodayTasksView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todayTasks) { task in
                    TaskRow(task: task, isSelected: task.isCompleted)
                        .onTapGesture {
                            toggleTaskCompletion(task)
                        }
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("Поток")
            .sheet(isPresented: $showingAddTask) {
                TaskEditorView(viewModel: viewModel, task: Task(id: UUID(), title: "", startTime: Date(), duration: 3600, color: .blue, icon: "circle", category: .work), isPresented: $showingAddTask)
            }
        }
    }
    
    private var todayTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return viewModel.tasks.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = todayTasks[index]
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
