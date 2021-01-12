import Foundation

/// Interface describing the Notification Center
public protocol NotificationCenterInterface {
    /// add observer
    func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol
    /// Remove observer
    func removeObserver(_ observer: Any)
}

extension NotificationCenter: NotificationCenterInterface{}

