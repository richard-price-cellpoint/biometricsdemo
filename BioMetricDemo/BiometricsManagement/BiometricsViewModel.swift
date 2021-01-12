import Combine
import SwiftUI

class BiometricsViewModel: ObservableObject {
    private var biometricsManager: BiometricsManager

    @Published var informationText = "Biometric authentication is not available"

    @Published var isSettingsButtonHidden = false

    @Published var isBiometricLoginEnabled = false

    private var cancellables: [AnyCancellable] = []


    init(biometricsManager: BiometricsManager = BiometricsManager() ) {
        self.biometricsManager = biometricsManager
        setUpBindings()
    }

    func authenticateUser(completion: @escaping (Result<String, Error>) -> Void) {
        biometricsManager.authenticateUser(completion: completion)
    }

    func determineBiometricsState() {
        biometricsManager.determineBiometricsState()
    }

    // Pull out into state extension
    private func information(from state: BiometricsState) -> String {
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
            return """
            FaceID authentication has been turned off, it can be reenabled in Settings,
            Passcode authentication will be used
            """
        }
    }

    private func hideSettingsButton(from state: BiometricsState) -> Bool {
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

    private func enableBiometricLogin(from state: BiometricsState) -> Bool {
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

    private func setUpBindings() {
        self.biometricsManager
            .$biometricsState
            .map(self.information)
            .assign(to: \.informationText, on: self)
            .store(in: &cancellables)

        self.biometricsManager
            .$biometricsState
            .map(self.hideSettingsButton)
            .assign(to: \.isSettingsButtonHidden, on: self)
            .store(in: &cancellables)

        self.biometricsManager
            .$biometricsState
            .map(self.enableBiometricLogin)
            .assign(to: \.isBiometricLoginEnabled, on: self)
            .store(in: &cancellables)
    }
}
