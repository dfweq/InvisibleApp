import Cocoa

class ViewController: NSViewController {
    
    private var statusLabel: NSTextField!
    private var secretTextField: NSTextField!
    private var secretDisplay: NSTextView!
    private var scrollView: NSScrollView!
    private var imageView: NSImageView!
    private var clearButton: NSButton!
    private var isShowingImage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.wantsLayer = true
        
        // Set up UI elements
        setupUI()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Configure window
        if let window = self.view.window {
            window.isMovable = false
            window.level = .floating
            window.sharingType = .none
            
            // Make sure the window has proper style mask to be interactive
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            
            // Set title
            window.title = "Invisible Notes"
        }
    }
    
    private func setupUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Invisible Notes")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        view.addSubview(titleLabel)
        
        // Status label
        statusLabel = NSTextField(labelWithString: "Invisible during screen sharing (⌥⇧I to toggle, ⌥⇧S for screenshot)")
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.isBezeled = false
        statusLabel.isEditable = false
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Secret text input
        secretTextField = NSTextField()
        secretTextField.placeholderString = "Enter sensitive information here"
        secretTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(secretTextField)
        
        // Secret display
        secretDisplay = NSTextView()
        secretDisplay.isEditable = true
        secretDisplay.backgroundColor = NSColor.textBackgroundColor
        secretDisplay.textColor = NSColor.labelColor
        secretDisplay.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        // Put text view in a scroll view
        scrollView = NSScrollView()
        scrollView.documentView = secretDisplay
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)
        
        // Image view for screenshots
        imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.isHidden = true  // Hide by default
        imageView.wantsLayer = true
        imageView.layer?.borderWidth = 1
        imageView.layer?.borderColor = NSColor.gray.cgColor
        imageView.layer?.cornerRadius = 4
        view.addSubview(imageView)
        
        // Clear button for screenshots
        clearButton = NSButton(title: "Clear Screenshot", target: self, action: #selector(clearScreenshot))
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.bezelStyle = .rounded
        clearButton.isHidden = true  // Hide by default
        view.addSubview(clearButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            secretTextField.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 15),
            secretTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            secretTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
            scrollView.topAnchor.constraint(equalTo: secretTextField.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
            
            // Image view constraints (same position as scroll view)
            imageView.topAnchor.constraint(equalTo: secretTextField.bottomAnchor, constant: 15),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
            
            // Clear button
            clearButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 15),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
        ])
        
        // Set up text field delegate
        secretTextField.delegate = self
    }
    
    // Method to display a screenshot
    func displayScreenshot(_ image: NSImage) {
        // Hide the text view and text field, show the image view and clear button
        scrollView.isHidden = true
        secretTextField.isHidden = true
        imageView.isHidden = false
        clearButton.isHidden = false
        
        // Set the image
        imageView.image = image
        
        // Update status label
        statusLabel.stringValue = "Screenshot captured (⌥⇧I to toggle, ⌥⇧S for new screenshot)"
        
        // Update state
        isShowingImage = true
    }
    
    // Method to clear the screenshot and show notes
    @objc func clearScreenshot() {
        if isShowingImage {
            // Hide the image view and clear button, show the text view and text field
            scrollView.isHidden = false
            secretTextField.isHidden = false
            imageView.isHidden = true
            clearButton.isHidden = true
            
            // Update state
            isShowingImage = false
            
            // Update status label
            statusLabel.stringValue = "Invisible during screen sharing (⌥⇧I to toggle, ⌥⇧S for screenshot)"
        }
    }
}

// MARK: - NSTextFieldDelegate
extension ViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField == secretTextField {
            // Append text to the text view for multi-line support
            let currentText = secretDisplay.string
            secretDisplay.string = currentText.isEmpty ?
                textField.stringValue :
                currentText + "\n" + textField.stringValue
            
            // Clear the single-line field once transferred
            textField.stringValue = ""
        }
    }
}
