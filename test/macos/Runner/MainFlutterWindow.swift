import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Reproducible bench window size without UI scripting:
    //   BENCH_WINDOW=800x1042 "…/Test Demos"
    // (content area in logical points; matches docs/PROFILING.md runs).
    // Applied now and again on the next runloop turn — macOS window state
    // restoration can re-apply a saved frame after awakeFromNib.
    if let spec = ProcessInfo.processInfo.environment["BENCH_WINDOW"] {
      let parts = spec.lowercased().split(separator: "x").compactMap { Double($0) }
      if parts.count == 2 {
        let apply = { [weak self] in
          guard let self else { return }
          self.setContentSize(NSSize(width: parts[0], height: parts[1]))
          self.setFrameOrigin(NSPoint(x: 40, y: 40))
          NSLog("BENCH_WINDOW %@ -> frame %@", spec, NSStringFromRect(self.frame))
        }
        apply()
        DispatchQueue.main.async(execute: apply)
      } else {
        NSLog("BENCH_WINDOW %@ ignored (expected WxH)", spec)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
