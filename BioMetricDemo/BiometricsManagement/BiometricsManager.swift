import LocalAuthentication
import SwiftUI

internal let kFaceIDKey = "FaceIDAccepted"

class BiometricsManager {
    enum BioError: Error {
        case General
        case NoEvaluate
    }

    @Published private ( set ) var biometricsState: BiometricsState = .notAvailable

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
        canPerformOwnerAuthentication()
        canPerformBiometricAuthentication()

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

//        case (false, true, false, _):
//            biometricsState = .availableUserDenied

        case (true, _, false, .touchID):
            biometricsState = .touchIdAvailable

        case (true, true, true, .faceID):
            biometricsState = .faceIDAvailableUserEnabled

        case (true, false, true, .faceID):
            biometricsState = .faceIDAvailableUserDisabled

        case (false, _, _, _):
            biometricsState = .notAvailable

        default:
            biometricsState = .notAvailable
        }
    }

    private func canPerformOwnerAuthentication()  {
        var error: NSError?
        canOwnerAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        print("Error: \(String(describing: error))")
    }

    private func canPerformBiometricAuthentication() {
        var error: NSError?
        canBiometricallyAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        print("Error: \(String(describing: error))")
    }

//    func resetToInitialState(andRecreate newContext: LAContextProtocol = LAContext()) {
////        canOwnerAuthenticate = false
////        canBiometricallyAuthenticate = false
////        hasAcceptedBiometricTerms = false
//////        biometricsState = .notAvailable
////        context.invalidate()
////
////        context = newContext
////        determineBiometricsState()
//    }

    func authenticateUser(completion: @escaping (Result<String, Error>) -> Void) {
        determineBiometricsState()
        if case .notAvailable = biometricsState {
            completion( .failure(BioError.NoEvaluate) )
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
                self?.determineBiometricsState()
                switch evaluateError {
                default: completion(.failure(BiometricsManager.BioError.General))
                }
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
