import LocalAuthentication

// Interface describing LAContext
public protocol LAContextInterface {
    /// Can evaluate policy
    func canEvaluatePolicy(_ : LAPolicy, error: NSErrorPointer) -> Bool
    /// Evaluate policy
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void)
    /// Biometry type
    var biometryType: LABiometryType { get }
}

extension LAContext: LAContextInterface{}
