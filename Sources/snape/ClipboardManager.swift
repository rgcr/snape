import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private init() {}
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
