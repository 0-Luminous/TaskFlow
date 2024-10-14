import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @Binding var clockOffset: CGFloat
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue
    @State private var newCategoryIcon = "circle"
    
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
                        newCategoryName = ""
                        newCategoryColor = .blue
                        newCategoryIcon = "circle"
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
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        viewModel.removeCategories(at: offsets)
    }
}

