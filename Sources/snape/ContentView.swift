import SwiftUI
import AppKit

// Global state to track keyboard navigation
class PopoverState: ObservableObject {
    static let shared = PopoverState()
    @Published var isKeyboardNavigating: Bool = false
    @Published var currentPopoverView: SnippetRowNSView? = nil
    
    func showPopover(for view: SnippetRowNSView) {
        // Hide previous popover
        if let current = currentPopoverView, current !== view {
            current.hidePopover()
        }
        currentPopoverView = view
        view.showPopoverNow()
    }
    
    func hideAllPopovers() {
        currentPopoverView?.hidePopover()
        currentPopoverView = nil
    }
}

struct ContentView: View {
    @ObservedObject var snippetManager: SnippetManager
    @State private var selectedIndex: Int = 0
    @State private var isFilterMode: Bool = false
    @State private var filterText: String = ""
    @State private var showAbout: Bool = false
    @State private var showSettings: Bool = false
    @State private var showCopiedNotification: Bool = false
    
    let verbose: Bool
    
    // When filtering, show flat list without separators
    var filteredSnippets: [Snippet] {
        let allSnippets = snippetManager.getSnippetsOnly()
        if filterText.isEmpty {
            return allSnippets
        }
        let lowercasedFilter = filterText.lowercased()
        return allSnippets.filter {
            $0.displayName.lowercased().contains(lowercasedFilter) ||
            $0.content.lowercased().contains(lowercasedFilter)
        }
    }
    
    // Items to display (with separators when not filtering)
    var displayItems: [SnippetItem] {
        if filterText.isEmpty {
            return snippetManager.items
        } else {
            return filteredSnippets.map { .snippet($0) }
        }
    }
    
    // Map from display index to snippet index (skipping separators)
    var snippetIndices: [Int] {
        var indices: [Int] = []
        var snippetIndex = 0
        for item in displayItems {
            if case .snippet(_) = item {
                indices.append(snippetIndex)
                snippetIndex += 1
            }
        }
        return indices
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if isFilterMode {
                filterHeader
            } else {
                normalHeader
            }
            
            Divider()
            
            // Snippet list
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(displayItems.enumerated()), id: \.element.id) { displayIndex, item in
                        switch item {
                        case .separator(let name):
                            SeparatorRow(name: name)
                                .id(item.id)
                        case .snippet(let snippet):
                            let snippetIndex = getSnippetIndex(for: displayIndex)
                            SnippetRowWithPopover(
                                snippet: snippet,
                                indexChar: snippetManager.getIndexChar(for: snippetIndex),
                                isSelected: snippetIndex == selectedIndex
                            )
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 1) {
                                selectedIndex = snippetIndex
                                selectSnippet()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: selectedIndex) { newIndex in
                    if let itemId = getItemId(for: newIndex) {
                        withAnimation {
                            proxy.scrollTo(itemId, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button(action: openSnippetsFolder) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open Snippets Folder")
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(filteredSnippets.count) snippets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(KeyEventHandling(
            onKeyDown: handleKeyDown,
            onCharacter: handleCharacter
        ))
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay {
            if showCopiedNotification {
                CopiedNotificationView()
            }
        }
        .onAppear {
            snippetManager.loadSnippets()
        }
    }
    
    private func getSnippetIndex(for displayIndex: Int) -> Int {
        var snippetIndex = 0
        for i in 0..<displayIndex {
            if case .snippet(_) = displayItems[i] {
                snippetIndex += 1
            }
        }
        return snippetIndex
    }
    
    private func getItemId(for snippetIndex: Int) -> String? {
        var currentSnippetIndex = 0
        for item in displayItems {
            if case .snippet(let snippet) = item {
                if currentSnippetIndex == snippetIndex {
                    return snippet.id.uuidString
                }
                currentSnippetIndex += 1
            }
        }
        return nil
    }
    
    private var normalHeader: some View {
        Text("↑↓ Enter or [index]  |  '/' to filter  |  '?' for help")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
    }
    
    private var filterHeader: some View {
        VStack(spacing: 4) {
            Text("Filter mode - ESC to quit | ↑↓ Enter to select")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Search: \(filterText)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("▌")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
    
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up arrow
            PopoverState.shared.isKeyboardNavigating = true
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return true
            
        case 125: // Down arrow
            PopoverState.shared.isKeyboardNavigating = true
            if selectedIndex < filteredSnippets.count - 1 {
                selectedIndex += 1
            }
            return true
            
        case 36: // Return/Enter
            selectSnippet()
            return true
            
        case 53: // Escape
            if isFilterMode {
                exitFilterMode()
            } else {
                NSApplication.shared.terminate(nil)
            }
            return true
            
        case 51: // Backspace
            if isFilterMode && !filterText.isEmpty {
                filterText.removeLast()
                selectedIndex = 0
            }
            return true
            
        default:
            return false
        }
    }
    
    private func handleCharacter(_ char: Character) -> Bool {
        if isFilterMode {
            // In filter mode, add character to filter
            if char.isLetter || char.isNumber || char == " " || char == "-" || char == "_" || char == "." {
                filterText.append(char)
                selectedIndex = 0
                return true
            }
            return false
        }
        
        // Normal mode
        if char == "/" {
            enterFilterMode()
            return true
        }
        
        if char == "?" {
            showAbout = true
            return true
        }
        
        // Handle letter index shortcuts
        if let index = snippetManager.indexForChar(char), index < filteredSnippets.count {
            selectedIndex = index
            selectSnippet()
            return true
        }
        
        return false
    }
    
    private func selectSnippet() {
        guard filteredSnippets.indices.contains(selectedIndex) else { return }
        
        let snippet = filteredSnippets[selectedIndex]
        
        if verbose {
            print("Selected snippet: \(snippet.displayName)")
            print("Copying snippet to clipboard...")
        }
        
        ClipboardManager.shared.copyToClipboard(snippet.content)
        
        // Show copied notification
        showCopiedNotification = true
        
        // Delay to show notification, then quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func enterFilterMode() {
        isFilterMode = true
        filterText = ""
        selectedIndex = 0
    }
    
    private func exitFilterMode() {
        isFilterMode = false
        filterText = ""
        selectedIndex = 0
    }
    
    private func openSnippetsFolder() {
        NSWorkspace.shared.open(snippetManager.snippetsDirectory)
    }
}

struct CopiedNotificationView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Copied!")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct SeparatorRow: View {
    let name: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: 20)
            
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
    }
}

struct SnippetRowWithPopover: NSViewRepresentable {
    let snippet: Snippet
    let indexChar: Character
    let isSelected: Bool
    
    func makeNSView(context: Context) -> SnippetRowNSView {
        let view = SnippetRowNSView()
        view.snippet = snippet
        view.indexChar = indexChar
        view.isSelected = isSelected
        return view
    }
    
    func updateNSView(_ nsView: SnippetRowNSView, context: Context) {
        let wasSelected = nsView.isSelected
        nsView.snippet = snippet
        nsView.indexChar = indexChar
        nsView.isSelected = isSelected
        nsView.updateLabel()
        
        // Show/hide popover based on selection change (only for keyboard navigation)
        if isSelected && !wasSelected && PopoverState.shared.isKeyboardNavigating {
            PopoverState.shared.showPopover(for: nsView)
        }
    }
}

class SnippetRowNSView: NSView {
    var snippet: Snippet?
    var indexChar: Character = "a"
    var isSelected: Bool = false {
        didSet {
            updateSelectionAppearance()
        }
    }
    
    private var label: NSTextField!
    private var iconView: NSImageView!
    private var backgroundView: NSView!
    private var popover: NSPopover?
    private var trackingArea: NSTrackingArea?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Background for selection
        backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 4
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        
        // Icon
        iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
        iconView.contentTintColor = .secondaryLabelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        
        // Label
        label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        
        updateSelectionAppearance()
    }
    
    private func updateSelectionAppearance() {
        if isSelected {
            backgroundView?.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
            iconView?.contentTintColor = .controlAccentColor
            label?.textColor = .controlAccentColor
        } else {
            backgroundView?.layer?.backgroundColor = NSColor.clear.cgColor
            iconView?.contentTintColor = .secondaryLabelColor
            label?.textColor = .labelColor
        }
    }
    
    func updateLabel() {
        guard let snippet = snippet else { return }
        label.stringValue = "[\(indexChar)]    \(snippet.displayName)"
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        // Only show popover on hover if not keyboard navigating
        if !PopoverState.shared.isKeyboardNavigating {
            PopoverState.shared.showPopover(for: self)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        // Only hide on mouse exit if not keyboard navigating
        if !PopoverState.shared.isKeyboardNavigating {
            hidePopover()
            if PopoverState.shared.currentPopoverView === self {
                PopoverState.shared.currentPopoverView = nil
            }
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        // Reset keyboard navigation mode when mouse moves
        PopoverState.shared.isKeyboardNavigating = false
    }
    
    func showPopoverNow() {
        guard let snippet = snippet else { return }
        
        // Close existing popover first
        hidePopover()
        
        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 200)
        
        let contentView = PreviewPopoverView(snippet: snippet)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        self.popover = popover
        
        popover.show(relativeTo: bounds, of: self, preferredEdge: .maxX)
    }
    
    func showPopover() {
        showPopoverNow()
    }
    
    func hidePopover() {
        popover?.close()
        popover = nil
    }
}

struct PreviewPopoverView: View {
    let snippet: Snippet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentColor)
                Text(snippet.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            
            Divider()
            
            // Content
            ScrollView {
                Text(snippet.content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(width: 320, height: 200)
    }
}

// Custom NSViewRepresentable to capture keyboard events
struct KeyEventHandling: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    let onCharacter: (Character) -> Bool
    
    func makeNSView(context: Context) -> KeyEventView {
        let view = KeyEventView()
        view.onKeyDown = onKeyDown
        view.onCharacter = onCharacter
        return view
    }
    
    func updateNSView(_ nsView: KeyEventView, context: Context) {
        nsView.onKeyDown = onKeyDown
        nsView.onCharacter = onCharacter
    }
}

class KeyEventView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    var onCharacter: ((Character) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        // First try special keys
        if let handler = onKeyDown, handler(event) {
            return
        }
        
        // Then try character input
        if let characters = event.characters, let char = characters.first {
            if let handler = onCharacter, handler(char) {
                return
            }
        }
        
        super.keyDown(with: event)
    }
}
