import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State private var taskTitle = ""
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 3600
    @State private var category: TaskCategory = .work
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название задачи", text: $taskTitle)
                DatePicker("Время начала", selection: $startTime, displayedComponents: .hourAndMinute)
                Picker("Продолжительность", selection: $duration) {
                    Text("30 минут").tag(TimeInterval(1800))
                    Text("1 час").tag(TimeInterval(3600))
                    Text("2 часа").tag(TimeInterval(7200))
                }
                Picker("Категория", selection: $category) {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .navigationTitle("Добавить задачу")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let newTask = Task(
                            title: taskTitle,
                            startTime: startTime,
                            duration: duration,
                            color: category.color,
                            icon: category.iconName, // Используем иконку категории
                            category: category
                        )
                        viewModel.addTask(newTask)
                        isPresented = false
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTaskView(viewModel: ClockViewModel(), isPresented: .constant(true))
}
