import SwiftUI
import Foundation

struct TaskEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State private var editedTask: Task
    @State private var showingDeleteConfirmation = false
    @State private var isRepeating = false
    @State private var repeatPattern = RepeatPattern(type: .daily, count: 1)
    
    init(viewModel: ClockViewModel, task: Task, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._editedTask = State(initialValue: task)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название задачи", text: $editedTask.title)
                DatePicker("Время начала", selection: $editedTask.startTime, displayedComponents: [.hourAndMinute, .date])
                DatePicker("Конец", selection: Binding(
                    get: { editedTask.startTime.addingTimeInterval(editedTask.duration) },
                    set: { editedTask.duration = $0.timeIntervalSince(editedTask.startTime) }
                ), in: editedTask.startTime..., displayedComponents: [.hourAndMinute, .date])
                Picker("Категория", selection: $editedTask.category) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.iconName)
                            .foregroundColor(category.color)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
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
            task: Task(id: UUID(), title: "Пример задачи", startTime: Date(), duration: 3600, color: .blue, icon: "circle", category: .work),
            isPresented: .constant(true)
        )
    }
}

#Preview {
    TaskEditorView(
        viewModel: ClockViewModel(),
        task: Task(id: UUID(), title: "Пример задачи", startTime: Date(), duration: 3600, color: .blue, icon: "circle", category: .work),
        isPresented: .constant(true)
    )
}
