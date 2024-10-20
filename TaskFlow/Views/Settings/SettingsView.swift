//
//  SettingsView.swift
//  TaskFlow
//
//  Created by Yan on 13/10/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("sortOption") private var sortOption = SortOption.startTime.rawValue
    @AppStorage("clockFaceColor") private var clockFaceColor = Color.white.toHex()
    
    @State private var tempClockFaceColor = Color.white
    
    enum SortOption: String, CaseIterable, Identifiable {
        case startTime = "Началу"
        case title = "Заголовку"
        case category = "Категории"
        
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Внешний вид")) {
                    Toggle("Темная тема", isOn: $isDarkMode)
                    ColorPicker("Цвет циферблата", selection: $tempClockFaceColor)
                        .onChange(of: tempClockFaceColor) { oldValue, newValue in
                            clockFaceColor = newValue.toHex()
                        }
                }
                
                Section(header: Text("Уведомления")) {
                    Toggle("Включить уведомления", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("Сортировка задач")) {
                    Picker("Сортировать по", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: resetSettings) {
                        Text("Сбросить настройки")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempClockFaceColor = Color(hex: clockFaceColor)
        }
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        sortOption = SortOption.startTime.rawValue
        clockFaceColor = Color.white.toHex()
        tempClockFaceColor = .white
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
