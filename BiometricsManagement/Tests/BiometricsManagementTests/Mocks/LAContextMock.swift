@testable import BiometricsManagement
import LocalAuthentication

class LAContextMock: LAContextInterface {
    var canEvaluateBio: Bool = true
    var canEvaluate: Bool = true
    var reason: String?
    var biometryType: LABiometryType = .touchID
    var contextError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
    var shouldChangeBioError = true
    var laPolicy: LAPolicy?
    var evaluateReply: ((Bool, Error?) -> Void)?

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if policy == .deviceOwnerAuthentication {
            if !canEvaluate {
                error?.pointee = contextError as NSError?
            }
            return canEvaluate
        } else {
            if !canEvaluateBio && shouldChangeBioError {
                contextError = try? LAError.error(from: kLAErrorTouchIDNotAvailable)
                error?.pointee = contextError as NSError?
            }
            return canEvaluateBio
        }
    }

    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        laPolicy = policy
        evaluateReply = reply
    }
}
