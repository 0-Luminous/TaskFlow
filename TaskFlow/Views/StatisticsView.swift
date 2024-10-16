import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedDate = Date()
    @State private var showingExportSheet = false
    @State private var csvString = ""

    var body: some View {
        NavigationView {
            List {
                DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                Section(header: Text("Задачи на выбранную дату")) {
                    ForEach(viewModel.tasksForDate(selectedDate)) { task in
                        TaskRow(task: task, isSelected: false)
                    }
                }

                Section(header: Text("Статистика по категориям")) {
                    CategoryChart(data: viewModel.tasksByCategory())
                        .frame(height: 300)
                        .padding()
                }

                Section {
                    Button("Экспортировать все задачи") {
                        csvString = viewModel.exportTasksToCSV()
                        showingExportSheet = true
                    }
                }
            }
            .navigationTitle("Статистика")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        csvString = viewModel.exportTasksToCSV()
                        showingExportSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ActivityViewController(activityItems: [csvString])
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct CategoryChart: View {
    let data: [TaskCategory: [Task]]
    
    var body: some View {
        Chart {
            ForEach(Array(data.keys), id: \.self) { category in
                BarMark(
                    x: .value("Категория", category.rawValue),
                    y: .value("Количество задач", data[category]?.count ?? 0)
                )
                .foregroundStyle(category.color)
            }
        }
    }
}

#Preview {
    StatisticsView(viewModel: ClockViewModel())
}
