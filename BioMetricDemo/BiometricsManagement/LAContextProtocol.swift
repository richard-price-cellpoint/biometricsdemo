import LocalAuthentication

protocol LAContextProtocol {
    func canEvaluatePolicy(_ : LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void)
    func invalidate()
    var biometryType: LABiometryType { get }
}

extension LAContext: LAContextProtocol{}
