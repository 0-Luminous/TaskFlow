import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State private var taskTitle = ""
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 3600
    @State private var color = Color.blue
    @State private var icon: String = "circle"
    @State private var category: TaskCategory = .work // Переименовано из Category
    
    let icons = ["bed.double", "fork.knife", "figure.walk", "laptopcomputer", "leaf", "building.2", "moon", "sun.max"]
    
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
                ColorPicker("Цвет", selection: $color)
                Picker("Иконка", selection: $icon) {
                    ForEach(icons, id: \.self) { iconName in
                        Image(systemName: iconName).tag(iconName)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                // Добавлен Picker для выбора категории
                Picker("Категория", selection: $category) { // Переименовано
                    ForEach(TaskCategory.allCases, id: \.self) { category in // Переименовано
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
                            id: UUID(),
                            title: taskTitle,
                            startTime: startTime,
                            duration: duration,
                            color: categoryColor(category),
                            icon: icon,
                            category: category // Переименовано
                        )
                        viewModel.addTask(newTask)
                        isPresented = false
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
    }
    
    // Функция для определения цвета на основе категории
    func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .food:
            return .green
        case .sport:
            return .red
        case .sleep:
            return .blue
        case .work:
            return .orange
        default:
            return category.color
        }
    }
}

#Preview {
    AddTaskView(viewModel: ClockViewModel(), isPresented: .constant(true))
}
