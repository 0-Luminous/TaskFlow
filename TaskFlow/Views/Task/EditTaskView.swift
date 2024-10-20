import SwiftUI

struct EditTaskView: View {
    var task: Task
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ClockViewModel
    
    @State private var taskTitle: String
    @State private var startTime: Date
    @State private var duration: TimeInterval
    @State private var icon: String
    @State private var category: TaskCategory
    
    let icons = ["bed.double", "fork.knife", "figure.walk", "laptopcomputer", "leaf", "building.2", "moon", "sun.max"]
    
    init(task: Task, isPresented: Binding<Bool>, viewModel: ClockViewModel) {
        self.task = task
        self._isPresented = isPresented
        self.viewModel = viewModel
        self._taskTitle = State(initialValue: task.title)
        self._startTime = State(initialValue: task.startTime)
        self._duration = State(initialValue: task.duration)
        self._icon = State(initialValue: task.icon)
        self._category = State(initialValue: task.category)
    }
    
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
                Picker("Иконка", selection: $icon) {
                    ForEach(icons, id: \.self) { iconName in
                        Image(systemName: iconName).tag(iconName)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Picker("Категория", selection: $category) {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .navigationTitle("Редактировать задачу")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let updatedTask = Task(
                            id: task.id,
                            title: taskTitle,
                            startTime: startTime,
                            duration: duration,
                            color: category.color, // Используем цвет категории
                            icon: icon,
                            category: category
                        )
                        viewModel.updateTask(updatedTask)
                        isPresented = false
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditTaskView(task: Task(title: "Пример", startTime: Date(), duration: 3600, color: .blue, icon: "circle", category: .work), isPresented: .constant(true), viewModel: ClockViewModel())
}
