import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @Binding var clockOffset: CGFloat
    @State private var newCategory = TaskCategory(rawValue: "", color: .blue, iconName: "circle")
    @State private var editingCategory: TaskCategory?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Добавить новую категорию")) {
                    CategoryFormView(category: $newCategory)
                    Button(action: addCategory) {
                        Label("Добавить категорию", systemImage: "plus.circle")
                    }
                    .disabled(newCategory.rawValue.isEmpty)
                }
                
                Section(header: Text("Существующие категории")) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        CategoryRowView(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture { editingCategory = category }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
            .listStyle(InsetGroupedListStyle())
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
    
    private func addCategory() {
        viewModel.addCategory(name: newCategory.rawValue, color: newCategory.color, icon: newCategory.iconName)
        newCategory = TaskCategory(rawValue: "", color: .blue, iconName: "circle")
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        viewModel.removeCategories(at: offsets)
    }
}

struct CategoryFormView: View {
    @Binding var category: TaskCategory
    
    var body: some View {
        TextField("Название категории", text: Binding(
            get: { category.rawValue },
            set: { newValue in
                category = TaskCategory(rawValue: newValue, color: category.color, iconName: category.iconName)
            }
        ))
        ColorPicker("Цвет категории", selection: Binding(
            get: { category.color },
            set: { newValue in
                category = TaskCategory(rawValue: category.rawValue, color: newValue, iconName: category.iconName)
            }
        ))
        IconPicker(selectedIcon: Binding(
            get: { category.iconName },
            set: { newValue in
                category = TaskCategory(rawValue: category.rawValue, color: category.color, iconName: newValue)
            }
        ))
    }
}

struct IconPicker: View {
    @Binding var selectedIcon: String
    @State private var showingIconPicker = false
    
    var body: some View {
        HStack {
            Text("Иконка категории")
            Spacer()
            Image(systemName: selectedIcon)
                .foregroundColor(.blue)
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
        .onTapGesture { showingIconPicker = true }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.presentationMode) var presentationMode
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(SFSymbols.categoryIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(selectedIcon == icon ? .blue : .primary)
                            .padding()
                            .background(
                                Circle()
                                    .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                                presentationMode.wrappedValue.dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Выберите иконку")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CategoryRowView: View {
    let category: TaskCategory
    
    var body: some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(category.color)
            Text(category.rawValue)
            Spacer()
            Circle()
                .fill(category.color)
                .frame(width: 20, height: 20)
        }
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

enum SFSymbols {
    static let categoryIcons = ["circle", "square", "triangle", "star", "heart", "flag", "tag", "bookmark", "book", "pencil", "folder", "paperclip", "link", "person", "house", "car", "airplane", "gift", "bell", "clock"]
}

