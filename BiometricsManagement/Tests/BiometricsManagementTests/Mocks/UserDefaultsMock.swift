@testable import BiometricsManagement

class UserDefaultsMock: UserDefaultsInterface {
    var termsAccepted = false

    func bool(forKey defaultName: String) -> Bool {
        return termsAccepted
    }

    func set(_ value: Bool, forKey defaultName: String) {
        if defaultName == "FaceIDAccepted" {
            termsAccepted = value
        }
    }
}
