import Cocoa

class ViewController: NSViewController {
    
    private var statusLabel: NSTextField!
    private var secretTextField: NSTextField!
    private var secretDisplay: NSTextView!
    
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
        statusLabel = NSTextField(labelWithString: "Invisible during screen sharing (⌥⇧I to toggle)")
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
        let scrollView = NSScrollView()
        scrollView.documentView = secretDisplay
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)
        
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
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
        ])
        
        // Set up text field delegate
        secretTextField.delegate = self
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
