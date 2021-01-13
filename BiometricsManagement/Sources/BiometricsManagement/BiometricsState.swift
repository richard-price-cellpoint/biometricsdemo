/// Biometrics State
public enum BiometricsState: Equatable {
    /// Biometrics are not available on the device
    case notAvailable(BiometricAuthenticationError)
    /// Biometrics are available but the user has declined usage
    case availableUserDenied
    /// Touch ID is available but the user has yet to give permission for  usage
    case touchIdAvailableNoUserPermission
    /// Touch ID is avaiklable
    case touchIdAvailable
    /// Face ID is available but the user has yet to give permission for  usage
    case faceIdAvailableNoUserPermission
    /// Face ID is avaiklable and its usage is enabled in the Settings
    case faceIDAvailableUserEnabled
    /// Face ID is avaiklable and its usage is disabled in the Settings
    case faceIDAvailableUserDisabled
}
