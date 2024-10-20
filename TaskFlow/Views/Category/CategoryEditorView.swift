import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @Binding var clockOffset: CGFloat
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue
    @State private var newCategoryIcon = "circle"
    @State private var editingCategory: TaskCategory?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Добавить новую категорию")) {
                    TextField("Название категории", text: $newCategoryName)
                    ColorPicker("Цвет категории", selection: $newCategoryColor)
                    Picker("Иконка категории", selection: $newCategoryIcon) {
                        ForEach(viewModel.availableIcons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    Button("Добавить категорию") {
                        viewModel.addCategory(name: newCategoryName, color: newCategoryColor, icon: newCategoryIcon)
                        resetNewCategoryFields()
                    }
                    .disabled(newCategoryName.isEmpty)
                }
                
                Section(header: Text("Существующие категории")) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.rawValue)
                            Spacer()
                            Circle()
                                .fill(category.color)
                                .frame(width: 20, height: 20)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
            .navigationTitle("Редактор категорий")
            .navigationBarItems(leading: Button("Назад") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    clockOffset = 0
                    isPresented = false
                }
            })
            .sheet(item: $editingCategory) { category in
                CategoryEditView(viewModel: viewModel, category: category, isPresented: $editingCategory)
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        viewModel.removeCategories(at: offsets)
    }
    
    private func resetNewCategoryFields() {
        newCategoryName = ""
        newCategoryColor = .blue
        newCategoryIcon = "circle"
    }
}

struct CategoryEditView: View {
    @ObservedObject var viewModel: ClockViewModel
    let category: TaskCategory
    @Binding var isPresented: TaskCategory?
    @State private var editedName: String
    @State private var editedColor: Color
    @State private var editedIcon: String
    
    init(viewModel: ClockViewModel, category: TaskCategory, isPresented: Binding<TaskCategory?>) {
        self.viewModel = viewModel
        self.category = category
        self._isPresented = isPresented
        self._editedName = State(initialValue: category.rawValue)
        self._editedColor = State(initialValue: category.color)
        self._editedIcon = State(initialValue: category.iconName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название категории", text: $editedName)
                ColorPicker("Цвет категории", selection: $editedColor)
                Picker("Иконка категории", selection: $editedIcon) {
                    ForEach(viewModel.availableIcons, id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
            }
            .navigationTitle("Редактировать категорию")
            .navigationBarItems(
                leading: Button("Отмена") { isPresented = nil },
                trailing: Button("Сохранить") {
                    viewModel.updateCategory(category, newName: editedName, newColor: editedColor, newIcon: editedIcon)
                    isPresented = nil
                }
                .disabled(editedName.isEmpty)
            )
        }
    }
}
