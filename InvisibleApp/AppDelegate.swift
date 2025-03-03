import Cocoa
import ScreenCaptureKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var isWindowVisible = false
    private var globalKeyboardMonitor: Any?
    private var mouseMoveMonitor: Any?
    private var mainWindow: NSWindow?
    private var captureEngine: ScreenCaptureEngine?
    
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
    
    // MARK: - Screen Capture
    
    // Class to handle screen capture
    class ScreenCaptureEngine: NSObject {
        private var stream: SCStream?
        private var captureCompletion: ((NSImage?) -> Void)?
        private var output: SCStreamOutput?
        private var contentFilter: SCContentFilter?
        
        func captureScreen(completion: @escaping (NSImage?) -> Void) {
            self.captureCompletion = completion
            
            // Start the capture process asynchronously
            Task {
                await startCapture()
            }
        }
        
        private func startCapture() async {
            do {
                // Get available screen content to capture
                let availableContent = try await SCShareableContent.current
                
                // Use only the main display for capture
                guard let mainDisplay = availableContent.displays.first else {
                    self.captureCompletion?(nil)
                    return
                }
                
                // Create a filter for the main display (excluding windows)
                self.contentFilter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
                
                // Create stream configuration
                let configuration = SCStreamConfiguration()
                configuration.width = Int(mainDisplay.width * 2)  // For Retina displays
                configuration.height = Int(mainDisplay.height * 2)
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
                configuration.queueDepth = 1
                
                // Create the capture stream
                let stream = SCStream(filter: self.contentFilter!, configuration: configuration, delegate: nil)
                
                // Create stream output
                self.output = CaptureStreamOutput(captureHandler: { [weak self] image in
                    self?.captureCompletion?(image)
                    
                    // Stop the session after capturing one frame
                    Task { @MainActor in
                        await self?.stopCapture()
                    }
                })
                
                // Add stream output
                try stream.addStreamOutput(self.output!, type: .screen, sampleHandlerQueue: DispatchQueue.main)
                
                // Start the stream
                try await stream.startCapture()
                
                // Store session
                self.stream = stream
            } catch {
                print("Error starting screen capture: \(error.localizedDescription)")
                self.captureCompletion?(nil)
            }
        }
        
        @MainActor
        private func stopCapture() async {
            do {
                if let stream = self.stream {
                    try await stream.stopCapture()
                    self.stream = nil
                }
            } catch {
                print("Error stopping capture: \(error.localizedDescription)")
            }
        }
    }

    // Class to handle stream output
    class CaptureStreamOutput: NSObject, SCStreamOutput {
        private let captureHandler: (NSImage?) -> Void
        
        init(captureHandler: @escaping (NSImage?) -> Void) {
            self.captureHandler = captureHandler
            super.init()
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
            guard type == .screen, let frame = createImageFromSampleBuffer(sampleBuffer) else { return }
            captureHandler(frame)
        }
        
        private func createImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> NSImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            
            return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        }
    }

    // Method to capture and display a screenshot
    private func captureAndDisplayScreenshot() {
        // Initialize the capture engine if needed
        if captureEngine == nil {
            captureEngine = ScreenCaptureEngine()
        }
        
        // Capture the screen
        captureEngine?.captureScreen { [weak self] screenshot in
            // Make sure we have a screenshot and run on main thread
            DispatchQueue.main.async {
                guard let self = self, let screenshot = screenshot else { return }
                
                // Show the window if it's not already visible
                if !self.isWindowVisible {
                    self.toggleWindowVisibility()
                }
                
                // Pass the screenshot to the ViewController
                if let viewController = self.mainWindow?.contentViewController as? ViewController {
                    viewController.displayScreenshot(screenshot)
                }
            }
        }
    }
    
    // MARK: - Status Bar
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Invisible App")
            
            // Set up menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show/Hide Window (⌥⇧I)", action: #selector(toggleWindow), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Take Screenshot (⌥⇧S)", action: #selector(takeScreenshot), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
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
            
            // New shortcut for screenshot: Option+Shift+S (1 is the key code for 's')
            if event.modifierFlags.contains(.option) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == 1 {
                DispatchQueue.main.async {
                    self?.captureAndDisplayScreenshot()
                }
            }
        }
        
        // Also add local monitor for when app is active
        _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Option+Shift+I
            if event.modifierFlags.contains(.option) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == 34 {
                DispatchQueue.main.async {
                    self?.toggleWindowVisibility()
                }
                return nil // Consume the event
            }
            
            // Check for Option+Shift+S
            if event.modifierFlags.contains(.option) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == 1 {
                DispatchQueue.main.async {
                    self?.captureAndDisplayScreenshot()
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
    
    // MARK: - Actions
    
    @objc private func toggleWindow() {
        toggleWindowVisibility()
    }
    
    @objc private func takeScreenshot() {
        captureAndDisplayScreenshot()
    }
    
    // MARK: - Window Management
    
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
