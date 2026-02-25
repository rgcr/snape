import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🧙")
                    .font(.largeTitle)
                Text("Snape - A Severus Snippet Manager")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Handle your snippets with Severus precision.")
                .foregroundColor(.secondary)
            
            Text("Version: 2.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Group {
                Text("Keyboard Shortcuts:")
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    shortcutRow("↑↓", "Navigate snippets")
                    shortcutRow("Enter", "Select snippet and copy to clipboard")
                    shortcutRow("a-z, A-Z", "Quick selection by index")
                    shortcutRow("/", "Enter filter mode")
                    shortcutRow("?", "Show this about page")
                    shortcutRow("Escape", "Quit (or exit filter mode)")
                }
            }
            
            Divider()
            
            Group {
                Text("Features:")
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    featureRow("Quick snippet access by index")
                    featureRow("Fuzzy filtering of snippets")
                    featureRow("Arrow key navigation")
                    featureRow("Mouse click selection")
                    featureRow("Native macOS clipboard integration")
                }
            }
            
            Divider()
            
            Group {
                Text("File Locations:")
                    .fontWeight(.semibold)
                
                Text("Snippets: ~/.config/snape/")
                    .font(.system(.body, design: .monospaced))
                
                Text("Each file in the snippets directory becomes a snippet, with the filename as the snippet name.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
        }
        .padding(20)
        .frame(width: 450, height: 450)
    }
    
    private func shortcutRow(_ key: String, _ description: String) -> some View {
        HStack {
            Text("•")
            Text(key)
                .font(.system(.body, design: .monospaced))
                .frame(width: 80, alignment: .leading)
            Text(description)
        }
        .font(.caption)
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack {
            Text("•")
            Text(text)
        }
        .font(.caption)
    }
}
