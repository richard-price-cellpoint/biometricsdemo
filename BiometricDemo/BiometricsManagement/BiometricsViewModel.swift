import Combine
import UIKit

/// Biometrics View Model
class BiometricsViewModel: ObservableObject {
    @Published var informationText = "Biometric authentication is not available"
    @Published var isSettingsButtonHidden = false
    @Published var isBiometricLoginEnabled = false

    private var biometricsManager: BiometricsManager
    private var observer: NSObjectProtocol?
    private var notificationCenter: NotificationCenterInterface

    /// Init
    public init(
        biometricsManager: BiometricsManager = BiometricsManager(),
        notificationCenter: NotificationCenterInterface = NotificationCenter.default
        ) {
        self.biometricsManager = biometricsManager
        self.notificationCenter = notificationCenter
        setUpProperties(from: self.biometricsManager.state)

        observer = self.notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else {
               return
            }
            self.setUpProperties(from: self.biometricsManager.state)
        }
    }

    /// Authenticate user
    public func authenticateUser(completion: @escaping (Result<String, Error>) -> Void) {
        biometricsManager.authenticateUser { [weak self] result in
            guard let self = self else {
               return
            }
            self.setUpProperties(from: self.biometricsManager.state)
            completion(result)
        }
    }

    private func setUpProperties(from state: BiometricsState) {
        self.informationText = BiometricsViewModel.information(from: state)
        self.isSettingsButtonHidden = BiometricsViewModel.hideSettingsButton(from: state)
        self.isBiometricLoginEnabled = BiometricsViewModel.enableBiometricLogin(from: state)
    }

    // Pull out into state extension
    private static func information(from state: BiometricsState) -> String {
        switch state {
        case .notAvailable(let error):
            return error.errorMessage()

        case .availableUserDenied:
            // TODO: How is this accessed? - should be tapped 'do not allow
            return "Biometric authentication usage was not allowed"

        case .touchIdAvailableNoUserPermission:
            return "Touch ID is available but permission for its usage is required"

        case .touchIdAvailable:
            return "TouchID is available"

        case .faceIdAvailableNoUserPermission:
            return "Face ID is available but permission for its usage is required"

        case .faceIDAvailableUserEnabled:
            return "FaceID authentication is enabled, it can be disabled in Settings"

        case .faceIDAvailableUserDisabled:
            return
                """
                FaceID authentication has been turned off, it can be reenabled in Settings,
                Passcode authentication will be used
                """
        }
    }

    private static func hideSettingsButton(from state: BiometricsState) -> Bool {
        switch state {
        case .touchIdAvailable,
             .notAvailable,
             .availableUserDenied,
             .touchIdAvailableNoUserPermission,
             .faceIdAvailableNoUserPermission:
            return true

        case .faceIDAvailableUserEnabled,
             .faceIDAvailableUserDisabled:
            return false
        }
    }

    private static func enableBiometricLogin(from state: BiometricsState) -> Bool {
        switch state {
        case .touchIdAvailable,
             .faceIDAvailableUserEnabled,
             .faceIDAvailableUserDisabled,
             .touchIdAvailableNoUserPermission,
             .faceIdAvailableNoUserPermission:
            return true
        case .notAvailable,
             .availableUserDenied:
            return false
        }
    }

    deinit {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
    }
}
