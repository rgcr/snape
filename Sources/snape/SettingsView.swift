import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var appearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("appTheme") var themeName: String = AppTheme.system.rawValue {
        didSet {
            applyTheme()
        }
    }
    
    @AppStorage("windowWidth") var windowWidth: Int = 420
    @AppStorage("windowHeight") var windowHeight: Int = 550
    
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: themeName) ?? .system }
        set { themeName = newValue.rawValue }
    }
    
    func applyTheme() {
        let appearance = currentTheme.appearance
        NSApplication.shared.windows.forEach { window in
            window.appearance = appearance
        }
    }
    
    func saveWindowSize(width: Int, height: Int) {
        windowWidth = width
        windowHeight = height
    }
}

// Keep ThemeManager as alias for backward compatibility
typealias ThemeManager = SettingsManager

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            Form {
                Picker("Theme", selection: $settings.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Text("Window size is saved automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding(16)
        }
        .frame(width: 300, height: 140)
    }
}
