import UIKit

@MainActor
enum Dialogs {
    static func alert(message: String, host: String?) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let controller = UIAlertController(title: host, message: message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in continuation.resume() })
            if !present(controller) { continuation.resume() }
        }
    }

    static func confirm(message: String, host: String?) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let controller = UIAlertController(title: host, message: message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel) { _ in continuation.resume(returning: false) })
            controller.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in continuation.resume(returning: true) })
            if !present(controller) { continuation.resume(returning: false) }
        }
    }

    private static func present(_ controller: UIViewController) -> Bool {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard var top = scene?.keyWindow?.rootViewController else { return false }
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(controller, animated: true)
        return true
    }
}
