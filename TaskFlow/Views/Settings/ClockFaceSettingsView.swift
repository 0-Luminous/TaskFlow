import SwiftUI

struct ClockFaceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var tempLightModeClockFaceColor = Color.white
    @State private var tempDarkModeClockFaceColor = Color.black
    @State private var currentDate = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack {
                PreviewClockFace(clockFaceColor: currentClockFaceColor, currentDate: currentDate)
                    .frame(height: 200)
                    .padding()
                
                Form {
                    Section(header: Text("Цвет циферблата")) {
                        ColorPicker("Светлая тема", selection: $tempLightModeClockFaceColor)
                            .onChange(of: tempLightModeClockFaceColor) { _, newValue in
                                lightModeClockFaceColor = newValue.toHex()
                            }
                        ColorPicker("Темная тема", selection: $tempDarkModeClockFaceColor)
                            .onChange(of: tempDarkModeClockFaceColor) { _, newValue in
                                darkModeClockFaceColor = newValue.toHex()
                            }
                    }
                    
                    Section {
                        Toggle("Темная тема", isOn: $isDarkMode)
                    }
                }
            }
            .navigationTitle("Настройки циферблата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempLightModeClockFaceColor = Color(hex: lightModeClockFaceColor) ?? .white
            tempDarkModeClockFaceColor = Color(hex: darkModeClockFaceColor) ?? .black
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private var currentClockFaceColor: Color {
        isDarkMode ? Color(hex: darkModeClockFaceColor) ?? .black : Color(hex: lightModeClockFaceColor) ?? .white
    }
}

struct PreviewClockFace: View {
    let clockFaceColor: Color
    let currentDate: Date
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                )
            
            // Маркеры часов
            ForEach(0..<12) { hour in
                PreviewClockMarker(hour: hour)
            }
            
            // Стрелки часов
            PreviewClockHands(currentDate: currentDate)
        }
    }
}

struct PreviewClockMarker: View {
    let hour: Int
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.primary)
                .frame(width: hour % 3 == 0 ? 3 : 1, height: hour % 3 == 0 ? 15 : 10)
        }
        .offset(y: -85)
        .rotationEffect(Angle.degrees(Double(hour) / 12 * 360))
    }
}

struct PreviewClockHands: View {
    let currentDate: Date
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Часовая стрелка
                PreviewClockHand(angle: hourAngle, length: geometry.size.width * 0.3, width: 4)
                // Минутная стрелка
                PreviewClockHand(angle: minuteAngle, length: geometry.size.width * 0.4, width: 3)
                // Секундная стрелка
                PreviewClockHand(angle: secondAngle, length: geometry.size.width * 0.45, width: 1)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var hourAngle: Angle {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let minute = Calendar.current.component(.minute, from: currentDate)
        return .degrees(Double(hour * 30) + Double(minute) / 2)
    }
    
    private var minuteAngle: Angle {
        let minute = Calendar.current.component(.minute, from: currentDate)
        return .degrees(Double(minute) * 6)
    }
    
    private var secondAngle: Angle {
        let second = Calendar.current.component(.second, from: currentDate)
        return .degrees(Double(second) * 6)
    }
}

struct PreviewClockHand: View {
    let angle: Angle
    let length: CGFloat
    let width: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.primary)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(angle)
    }
}

struct ClockFaceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ClockFaceSettingsView()
    }
}
