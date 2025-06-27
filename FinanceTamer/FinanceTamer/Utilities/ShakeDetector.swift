import Combine
import UIKit

class ShakeDetector: ObservableObject {
    @Published var shaken = false
    private var observer: NSObjectProtocol?
    
    init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.deviceDidShakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.shaken.toggle()
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
