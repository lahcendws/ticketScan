import UIKit
import Flutter

class MainFlutterWindow: NSObject, UIWindowDelegate {
  var flutterViewController: FlutterViewController?
  var window: UIWindow?

  override init() {
    super.init()
  }

  func createWindow() -> UIWindow {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = createFlutterViewController()
    window.makeKeyAndVisible()
    self.window = window
    return window
  }

  func createFlutterViewController() -> FlutterViewController {
    let flutterViewController = FlutterViewController(engine: FlutterEngine(name: "io.flutter"), nibName: nil, bundle: nil)
    flutterViewController.setViewController(nil)
    self.flutterViewController = flutterViewController
    return flutterViewController
  }
}