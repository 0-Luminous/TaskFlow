import SwiftUI

struct ClockMarker: View {
    let hour: Int
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.primary)
                .frame(width: hour % 3 == 0 ? 3 : 1, height: hour % 3 == 0 ? 15 : 10)
        }
        .offset(y: -UIScreen.main.bounds.width * 0.38)
        .rotationEffect(Angle.degrees(Double(hour) / 24 * 360))
    }
}

struct ClockFaceView: View {
    let currentDate: Date
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var draggedCategory: TaskCategoryModel?
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    @State private var dropLocation: CGPoint?
    let clockFaceColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            TaskArcsView(tasks: tasks, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            
            ClockMarksView()
            
            ClockHandView(currentDate: currentDate)
            
            if let location = dropLocation {
                Circle()
                    .fill(draggedCategory?.color ?? .clear)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.7)
        .padding()
        .animation(.spring(), value: tasks)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let category = draggedCategory else { return false }
            
            let dropPoint = location
            self.dropLocation = dropPoint
            
            let time = timeForLocation(dropPoint)
            
            let newTask = Task(
                id: UUID(),
                title: "Новая задача",
                startTime: time,
                duration: 3600,
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            viewModel.addTask(newTask)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dropLocation = nil
            }
            
            return true
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, viewModel: viewModel, isPresented: $showingTaskDetail)
            }
        }
    }
    
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(x: UIScreen.main.bounds.width * 0.35, y: UIScreen.main.bounds.width * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let normalizedAngle = (angle + .pi / 2).truncatingRemainder(dividingBy: .pi * 2)
        let hours = normalizedAngle / (.pi / 12)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = Int(hours)
        components.minute = Int((hours.truncatingRemainder(dividingBy: 1)) * 60)
        
        return Calendar.current.date(from: components) ?? currentDate
    }
}

struct TaskArcsView: View {
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(tasks) { task in
                ClockTaskArc(task: task, geometry: geometry, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            }
        }
    }
}

struct ClockTaskArc: View {
    let task: Task
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    var body: some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2
        let startAngle = angleForTime(task.startTime)
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let endAngle = angleForTime(endTime)
        
        ZStack {
            Path { path in
                path.addArc(center: center, radius: radius + 10, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
            
            // Добавляем иконку категории в середине дуги
            let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
            Image(systemName: task.category.iconName)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(task.category.color)
                        .frame(width: 20, height: 20)
                )
                .position(
                    x: center.x + (radius + 20) * cos(midAngle.radians),
                    y: center.y + (radius + 20) * sin(midAngle.radians)
                )
        }
        .onTapGesture {
            selectedTask = task
            showingTaskDetail = true
        }
    }
    
    private func angleForTime(_ time: Date) -> Angle {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: time))
        let minute = CGFloat(calendar.component(.minute, from: time))
        let totalMinutes = hour * 60 + minute
        return Angle(degrees: Double(totalMinutes) / 4 - 90)
    }
}

struct ClockHandView: View {
    let currentDate: Date
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let hourHandLength = radius * 1.22
                let angle = angleForTime(currentDate)
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle.radians)),
                    y: center.y + hourHandLength * CGFloat(sin(angle.radians))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(Color.red, lineWidth: 3)
        }
    }
    
    private func angleForTime(_ time: Date) -> Angle {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: time))
        let minute = CGFloat(calendar.component(.minute, from: time))
        let totalMinutes = hour * 60 + minute
        return Angle(degrees: Double(totalMinutes) / 2 - 90)
    }
}

struct ClockMarksView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24) { hour in
                let angle = CGFloat(hour) * .pi / 12
                let length: CGFloat = hour % 3 == 0 ? 15 : 10
                Path { path in
                    let start = CGPoint(
                        x: geometry.size.width / 2 + (geometry.size.width / 2 - length) * cos(angle),
                        y: geometry.size.height / 2 + (geometry.size.width / 2 - length) * sin(angle)
                    )
                    let end = CGPoint(
                        x: geometry.size.width / 2 + (geometry.size.width / 2) * cos(angle),
                        y: geometry.size.height / 2 + (geometry.size.width / 2) * sin(angle)
                    )
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(Color.primary, lineWidth: hour % 3 == 0 ? 2 : 1)
                
                if hour % 3 == 0 {
                    Text("\(hour)")
                        .font(.system(size: 14, weight: .bold))
                        .position(
                            x: geometry.size.width / 2 + (geometry.size.width / 2 - 30) * cos(angle),
                            y: geometry.size.height / 2 + (geometry.size.width / 2 - 30) * sin(angle)
                        )
                }
            }
        }
    }
}
