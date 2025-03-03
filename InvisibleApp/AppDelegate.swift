import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var isWindowVisible = false
    private var globalKeyboardMonitor: Any?
    private var mouseMoveMonitor: Any?
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Store reference to main window
        mainWindow = NSApp.windows.first
        
        // Configure main window
        if let window = mainWindow {
            // Configure window properties
            window.isMovable = false
            window.level = .floating
            window.sharingType = .none
            
            // Set the proper style mask to ensure the window can become key
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            
            // Hide window initially
            window.orderOut(nil)
        }
        
        // Set up status bar icon
        setupStatusBar()
        
        // Set up global keyboard shortcut
        setupGlobalKeyboardShortcut()
        
        // Set up mouse tracking
        setupMouseTracking()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up monitors
        if let monitor = globalKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Invisible App")
            
            // Set up menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show/Hide Window (⌥⇧I)", action: #selector(toggleWindow), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
        }
    }
    
    private func setupGlobalKeyboardShortcut() {
        // Use global monitor to catch events outside the application
        globalKeyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Option+Shift+I (34 is the key code for 'i')
            if event.modifierFlags.contains(.option) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == 34 {
                DispatchQueue.main.async {
                    self?.toggleWindowVisibility()
                }
            }
        }
        
        // Also add local monitor for when app is active
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Option+Shift+I
            if event.modifierFlags.contains(.option) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == 34 {
                DispatchQueue.main.async {
                    self?.toggleWindowVisibility()
                }
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func setupMouseTracking() {
        // Track mouse movements globally
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            if self?.isWindowVisible == true {
                DispatchQueue.main.async {
                    self?.updateWindowPosition()
                }
            }
        }
    }
    
    @objc private func toggleWindow() {
        toggleWindowVisibility()
    }
    
    private func toggleWindowVisibility() {
        guard let window = mainWindow else { return }
        
        isWindowVisible.toggle()
        
        if isWindowVisible {
            // Update position before showing
            updateWindowPosition()
            
            // Show window
            window.orderFront(nil)
            
            // Make the window key and active
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Hide window
            window.orderOut(nil)
        }
        
        // Update status bar icon
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: isWindowVisible ? "eye" : "eye.slash",
                                   accessibilityDescription: "Invisible App")
        }
        
        // Provide audio feedback
        NSSound.beep()
    }
    
    private func updateWindowPosition() {
        guard let window = mainWindow, isWindowVisible else { return }
        
        // Get current mouse position in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        
        // Get current frame
        var frame = window.frame
        
        // Position the top-left corner at mouse position
        let newOrigin = NSPoint(x: mouseLocation.x, y: mouseLocation.y - frame.height)
        
        // Find the current screen containing the mouse cursor
        let currentScreen = NSScreen.screens.first(where: {
            NSMouseInRect(mouseLocation, $0.frame, false)
        }) ?? NSScreen.main
        
        // Ensure window stays within screen bounds
        if let screenFrame = currentScreen?.visibleFrame {
            let adjustedOrigin = NSPoint(
                x: min(max(newOrigin.x, screenFrame.minX), screenFrame.maxX - frame.width),
                y: min(max(newOrigin.y, screenFrame.minY), screenFrame.maxY - frame.height)
            )
            
            // Set the new position without animation
            frame.origin = adjustedOrigin
            window.setFrame(frame, display: true, animate: false)
        }
        
        // Always make sure it's not movable even if macOS tries to reset it
        window.isMovable = false
    }
}
