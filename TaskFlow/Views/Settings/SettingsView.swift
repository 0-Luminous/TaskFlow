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
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor = Color.black.toHex()
    
    @State private var tempLightModeClockFaceColor = Color.white
    @State private var tempDarkModeClockFaceColor = Color.black
    
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
                    ColorPicker("Цвет циферблата (светлая тема)", selection: $tempLightModeClockFaceColor)
                        .onChange(of: tempLightModeClockFaceColor) { _, newValue in
                            lightModeClockFaceColor = newValue.toHex()
                        }
                    ColorPicker("Цвет циферблата (темная тема)", selection: $tempDarkModeClockFaceColor)
                        .onChange(of: tempDarkModeClockFaceColor) { _, newValue in
                            darkModeClockFaceColor = newValue.toHex()
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
            tempLightModeClockFaceColor = Color(hex: lightModeClockFaceColor)
            tempDarkModeClockFaceColor = Color(hex: darkModeClockFaceColor)
        }
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        sortOption = SortOption.startTime.rawValue
        lightModeClockFaceColor = Color.white.toHex()
        darkModeClockFaceColor = Color.black.toHex()
        tempLightModeClockFaceColor = .white
        tempDarkModeClockFaceColor = .black
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
