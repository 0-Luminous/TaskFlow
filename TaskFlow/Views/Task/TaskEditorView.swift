import SwiftUI
import Foundation

struct TaskEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State private var editedTask: Task
    @State private var showingDeleteConfirmation = false
    @State private var isRepeating = false
    @State private var repeatPattern = RepeatPattern(type: .daily, count: 1)
    
    init(viewModel: ClockViewModel, task: Task? = nil, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        if let task = task {
            self._editedTask = State(initialValue: task)
        } else {
            self._editedTask = State(initialValue: Task(
                id: UUID(),
                title: "",
                startTime: Date(),
                duration: 3600,
                color: .blue,
                icon: "circle",
                category: .work,
                isCompleted: false
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название задачи", text: $editedTask.title)
                    DatePicker("Время начала", selection: $editedTask.startTime, displayedComponents: [.hourAndMinute, .date])
                    Picker("Продолжительность", selection: $editedTask.duration) {
                        Text("30 минут").tag(TimeInterval(1800))
                        Text("1 час").tag(TimeInterval(3600))
                        Text("1.5 часа").tag(TimeInterval(5400))
                        Text("2 часа").tag(TimeInterval(7200))
                        Text("3 часа").tag(TimeInterval(10800))
                        Text("4 часа").tag(TimeInterval(14400))
                    }
                }
                
                Section(header: Text("Категория")) {
                    Picker("Категория", selection: $editedTask.category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .foregroundColor(category.color)
                                .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Повторение")) {
                    Toggle("Повторять задачу", isOn: $isRepeating)
                    
                    if isRepeating {
                        Picker("Тип повторения", selection: $repeatPattern.type) {
                            Text("Ежедневно").tag(RepeatPatternType.daily)
                            Text("Еженедельно").tag(RepeatPatternType.weekly)
                            Text("Ежемесячно").tag(RepeatPatternType.monthly)
                        }
                        
                        Stepper("Количество повторений: \(repeatPattern.count)", value: $repeatPattern.count, in: 1...30)
                    }
                }
                
                if editedTask.id != UUID() {
                    Section {
                        Button("Удалить задачу") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(editedTask.id == UUID() ? "Новая задача" : "Редактор задачи")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if editedTask.id == UUID() {
                            if isRepeating {
                                viewModel.addRepeatingTask(editedTask, repeatPattern: repeatPattern)
                            } else {
                                viewModel.addTask(editedTask)
                            }
                        } else {
                            viewModel.updateTask(editedTask)
                        }
                        isPresented = false
                    }
                    .disabled(editedTask.title.isEmpty)
                }
            }
            .alert("Удалить задачу?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    viewModel.removeTask(editedTask)
                    isPresented = false
                }
            } message: {
                Text("Вы уверены, что хотите удалить эту задачу?")
            }
        }
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TaskEditorView(
            viewModel: ClockViewModel(),
            task: Task(
                id: UUID(),
                title: "Пример задачи",
                startTime: Date(),
                duration: 3600,
                color: .blue,
                icon: "circle",
                category: .work,
                isCompleted: false
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview {
    TaskEditorView(
        viewModel: ClockViewModel(),
        isPresented: .constant(true)
    )
}
