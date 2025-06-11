import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Restore saved window frame or use defaults
    let savedFrame = getSavedWindowFrame()
    
    self.contentViewController = flutterViewController
    self.setFrame(savedFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Set up window state saving
    setupWindowStateSaving()
    
    // Set corner radius to 50 pixels
    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = true
    
    // Remove any window chrome/borders
    self.isMovableByWindowBackground = true
    self.titlebarAppearsTransparent = true
    
    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.cornerRadius = 50
      contentView.layer?.masksToBounds = true
      contentView.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    super.awakeFromNib()
  }
  
  private func getSavedWindowFrame() -> NSRect {
    let defaults = UserDefaults.standard
    
    // Check if we have saved window state
    if defaults.object(forKey: "windowFrame") != nil {
      let frameString = defaults.string(forKey: "windowFrame") ?? ""
      let savedFrame = NSRectFromString(frameString)
      
      // Validate the frame is reasonable (not empty and on screen)
      if !savedFrame.isEmpty && savedFrame.width > 100 && savedFrame.height > 100 {
        // Check if the frame is at least partially on screen
        let screens = NSScreen.screens
        for screen in screens {
          if screen.frame.intersects(savedFrame) {
            return savedFrame
          }
        }
      }
    }
    
    // Default frame if no valid saved state
    let defaultSize = NSSize(width: 600, height: 400)
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = screenFrame.midX - defaultSize.width / 2
      let y = screenFrame.midY - defaultSize.height / 2
      return NSRect(x: x, y: y, width: defaultSize.width, height: defaultSize.height)
    }
    
    return NSRect(x: 100, y: 100, width: defaultSize.width, height: defaultSize.height)
  }
  
  private func setupWindowStateSaving() {
    // Save window state when window moves or resizes
    NotificationCenter.default.addObserver(
      forName: NSWindow.didMoveNotification,
      object: self,
      queue: nil
    ) { _ in
      self.saveWindowFrame()
    }
    
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResizeNotification,
      object: self,
      queue: nil
    ) { _ in
      self.saveWindowFrame()
    }
  }
  
  private func saveWindowFrame() {
    let frameString = NSStringFromRect(self.frame)
    UserDefaults.standard.set(frameString, forKey: "windowFrame")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
