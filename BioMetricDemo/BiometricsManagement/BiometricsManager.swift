import LocalAuthentication
import SwiftUI

internal let kFaceIDKey = "FaceIDAccepted"

class BiometricsManager {
    @Published private ( set ) var biometricsState: BiometricsState = .notAvailable(.other)

    private var biometryType: LABiometryType {
        return context.biometryType
    }

    private var observer: NSObjectProtocol?
    private var canOwnerAuthenticate = false
    private var canBiometricallyAuthenticate = false
    private var context: LAContextProtocol

    private var hasAcceptedBiometricTerms = UserDefaults.standard.bool(forKey: kFaceIDKey)

    init(context: LAContextProtocol = LAContext() ) {
        self.context = context
        determineBiometricsState()

        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.determineBiometricsState()
        }
    }

    func determineBiometricsState() {
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

        // TODO: Richard. Handle not enrolled case

        case (true, true, false, .touchID):
            biometricsState = .touchIdAvailableNoUserPermission

        case (true, true, false, .faceID):
            biometricsState = .faceIdAvailableNoUserPermission

//        case (false, true, false, _):
//            biometricsState = .availableUserDenied

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
    }

    private func canPerformOwnerAuthentication(error: NSErrorPointer)  {
        canOwnerAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: error)
        print("Error: \(String(describing: error))")
        if error != nil {
            canPerformBiometricAuthentication(error: error)
        }
    }

    private func canPerformBiometricAuthentication(error: NSErrorPointer) {
        canBiometricallyAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: error)
        print("Error: \(String(describing: error))")
    }

    func authenticateUser(completion: @escaping (Result<String, Error>) -> Void) {
        determineBiometricsState()
        if case .notAvailable(let error) = biometricsState {
            completion( .failure(error) )
        }

        let loginReason = "Log in with Biometrics"

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
                    fatalError("Must have an error if not success")
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
        UserDefaults.standard.set(true, forKey: kFaceIDKey)
        hasAcceptedBiometricTerms = UserDefaults.standard.bool(forKey: kFaceIDKey)
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
