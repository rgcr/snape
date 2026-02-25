import ArgumentParser
import SwiftUI

struct Snape: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "snape",
        abstract: "🧙 Snape - A Severus Snippet Manager",
        discussion: """
            Handle your snippets with Severus precision.
            
            Configuration:
              Snippets directory: ~/.config/snape/
            
            The application will show a popup window with your available snippets.
            Select a snippet to copy it to the clipboard.
            
            Examples:
              snape                               # Show snippet selector (default size)
              snape --verbose                     # Show snippet selector with verbose output
              snape --width-size 300 --height-size 500  # Show with custom window size
            """,
        version: "2.0.0"
    )
    
    @Flag(name: .long, help: "Enable verbose output messages")
    var verbose: Bool = false
    
    @Option(name: .customLong("width-size"), help: "Set window width (200-600, default: 420)")
    var widthSize: Int = 420
    
    @Option(name: .customLong("height-size"), help: "Set window height (200-600, default: 550)")
    var heightSize: Int = 550
    
    func validate() throws {
        guard widthSize >= 200 && widthSize <= 600 else {
            throw ValidationError("width-size must be between 200 and 600 (got \(widthSize))")
        }
        guard heightSize >= 200 && heightSize <= 600 else {
            throw ValidationError("height-size must be between 200 and 600 (got \(heightSize))")
        }
    }
    
    func run() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        
        let delegate = SnapeAppDelegate(
            width: widthSize,
            height: heightSize,
            verbose: verbose
        )
        app.delegate = delegate
        app.run()
    }
}

class SnapeAppDelegate: NSObject, NSApplicationDelegate {
    let width: Int
    let height: Int
    let verbose: Bool
    var window: NSWindow?
    var clickOutsideMonitor: Any?
    
    init(width: Int, height: Int, verbose: Bool) {
        self.width = width
        self.height = height
        self.verbose = verbose
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let snippetManager = SnippetManager(verbose: verbose)
        
        // Use saved settings, CLI arguments override saved values
        let settings = SettingsManager.shared
        let finalWidth = (width != 420) ? width : settings.windowWidth
        let finalHeight = (height != 550) ? height : settings.windowHeight
        
        if verbose {
            print("Starting Snape snippet manager (size: \(finalWidth)x\(finalHeight))...")
            print("Snippets directory: \(snippetManager.snippetsDirectory.path)")
        }
        
        let contentView = ContentView(snippetManager: snippetManager, verbose: verbose)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: finalWidth, height: finalHeight),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.minSize = NSSize(width: 300, height: 300)
        
        window?.title = "Snape - Snippet Manager"
        window?.isRestorable = false  // Disable state restoration
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.delegate = self
        
        // Position window at cursor AFTER showing (overrides any restored position)
        let mouseLocation = NSEvent.mouseLocation
        var windowX = mouseLocation.x - CGFloat(finalWidth) / 2
        var windowY = mouseLocation.y - CGFloat(finalHeight) / 2
        
        // Keep window within screen bounds
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            
            // Clamp X position
            if windowX < screenFrame.minX {
                windowX = screenFrame.minX
            } else if windowX + CGFloat(finalWidth) > screenFrame.maxX {
                windowX = screenFrame.maxX - CGFloat(finalWidth)
            }
            
            // Clamp Y position
            if windowY < screenFrame.minY {
                windowY = screenFrame.minY
            } else if windowY + CGFloat(finalHeight) > screenFrame.maxY {
                windowY = screenFrame.maxY - CGFloat(finalHeight)
            }
        }
        
        window?.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        
        // Apply saved theme
        ThemeManager.shared.applyTheme()
        
        // Monitor for clicks outside the window
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            NSApplication.shared.terminate(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension SnapeAppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Save window size before closing
        if let window = window {
            let size = window.frame.size
            SettingsManager.shared.saveWindowSize(
                width: Int(size.width),
                height: Int(size.height)
            )
        }
        NSApplication.shared.terminate(nil)
    }
    
    func windowDidResize(_ notification: Notification) {
        // Save window size on resize
        if let window = window {
            let size = window.frame.size
            SettingsManager.shared.saveWindowSize(
                width: Int(size.width),
                height: Int(size.height)
            )
        }
    }
}

Snape.main()
