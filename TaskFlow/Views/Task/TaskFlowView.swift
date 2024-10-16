import SwiftUI

struct TaskFlowView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedTask: Task?
    @State private var isEditingTask = false

    var body: some View {
        List {
            ForEach(viewModel.tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                TaskRow(task: task, isSelected: selectedTask == task)
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
            .onDelete(perform: deleteTask)
        }
        .navigationTitle("Поток задач")
        .sheet(isPresented: $isEditingTask) {
            if let task = selectedTask {
                TaskEditorView(viewModel: viewModel, task: task, isPresented: $isEditingTask)
            }
        }
    }

    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let task = viewModel.tasks[index]
            viewModel.removeTask(task)
        }
    }
}

#Preview {
    NavigationView {
        TaskFlowView(viewModel: ClockViewModel())
    }
}
