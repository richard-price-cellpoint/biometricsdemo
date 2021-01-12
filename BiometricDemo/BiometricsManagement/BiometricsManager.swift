import LocalAuthentication

internal let kFaceIDKey = "FaceIDAccepted"

/// Biometrics Manager
public class BiometricsManager {
    public var state: BiometricsState {
        determineBiometricsState()
    }
    private var loginReason = "Log in with Biometrics"

    private var biometricsState: BiometricsState = .notAvailable(.other)
    private var biometryType: LABiometryType {
        return context.biometryType
    }

    private var observer: NSObjectProtocol?
    private var canOwnerAuthenticate = false
    private var canBiometricallyAuthenticate = false
    private var context: LAContextInterface
    private var userDefaults: UserDefaultsInterface
    private lazy var hasAcceptedBiometricTerms: Bool = {
        userDefaults.bool(forKey: kFaceIDKey)
    }()

    /// Init
    public init(
        context: LAContextInterface = LAContext(),
        userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.context = context
        self.userDefaults = userDefaults
        determineBiometricsState()
    }

    @discardableResult
    private func determineBiometricsState() -> BiometricsState {
        var error: NSError?
        canPerformOwnerAuthentication(error: &error)

        var authenticationError: BiometricAuthenticationError?
        if let laError = error as? LAError  {
            authenticationError = BiometricAuthenticationError.from(error: laError, biometryType: context.biometryType)
        }

        switch (
            canOwnerAuthenticate,
            canBiometricallyAuthenticate,
            hasAcceptedBiometricTerms,
            biometryType
        ) {

        case (true, true, false, .touchID):
            biometricsState = .touchIdAvailableNoUserPermission

        case (true, true, false, .faceID):
            biometricsState = .faceIdAvailableNoUserPermission

        case (true, _, false, .touchID):
            biometricsState = .touchIdAvailable

        case (true, true, true, .faceID):
            biometricsState = .faceIDAvailableUserEnabled

        case (true, false, true, .faceID):
            biometricsState = .faceIDAvailableUserDisabled

        case (false, _, _, _):
            biometricsState = .notAvailable(authenticationError ?? .other)

        default:
            biometricsState = .notAvailable(authenticationError ?? .other)
        }
        return biometricsState
    }

    private func canPerformOwnerAuthentication(error: NSErrorPointer)  {
        canOwnerAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: error)
        if error != nil {
            canPerformBiometricAuthentication(error: error)
        }
    }

    private func canPerformBiometricAuthentication(error: NSErrorPointer) {
        canBiometricallyAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: error)
    }

    /// Authenticate user
    func authenticateUser(completion: @escaping (Result<String, Error>) -> Void) {
        determineBiometricsState()
        if case .notAvailable(let error) = biometricsState {
            completion( .failure(error) )
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: loginReason) {[weak self] (success, evaluateError) in
            if success {
                DispatchQueue.main.async { [weak self] in
                    // User authenticated successfully
                    self?.saveTermsAcceptance()
                    self?.determineBiometricsState()
                    completion(.success("Success"))
                }
            } else {
                guard let error = evaluateError else {
                    fatalError("Must have an error if not a success")
                }
                self?.determineBiometricsState()
                guard let laError = error as? LAError else {
                    completion(.failure(error))
                    return
                }
                let authenticationError = BiometricAuthenticationError.from(
                    error: laError,
                    biometryType: self?.context.biometryType ?? .none
                )
                completion(.failure(authenticationError))
            }
        }
    }

    private func saveTermsAcceptance() {
        userDefaults.set(true, forKey: kFaceIDKey)
        hasAcceptedBiometricTerms = userDefaults.bool(forKey: kFaceIDKey)
    }
}
