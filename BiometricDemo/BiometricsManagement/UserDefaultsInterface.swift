import Foundation

/// Interface dsecribing the User defaults
public protocol UserDefaultsInterface {
    /// Bool for key
    func bool(forKey defaultName: String) -> Bool
    /// Set Bool for key
    func set(_ value: Bool, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsInterface {}
