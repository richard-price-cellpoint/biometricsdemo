import LocalAuthentication

/// Biometric authentication error
public enum BiometricAuthenticationError: Error {
    /// Authentication canceleld by user
    case cancelledByUser

    /// The user tapped the fallback button in the authentication dialog, but no fallback is
    /// available for the authentication policy.
    case userFallback

    /// Authentication cancelled by system
    case cancelledBySystem

    /// Passcode is not set on a FaceID enabled device
    case passcodeNotSetFaceId

    /// Passcode is not set on a TouchD enabled device
    case passcodeNotSetTouchId

    /// Biometry is not available
    case biometryNotAvailable

    /// FaceID not enrolled
    case faceIdNotEnrolled

    /// TouchID not enrolled
    case touchIdNotEnrolled

    /// FaceID is locked because there were too many failed attempts.
    case faceIdLockedOut

    /// TouchID is locked because there were too many failed attempts.
    case touchIdLockedOut

    /// FaceID Authentication failed
    case faceIdFailed

    /// TouchID Authentication failed
    case touchIdFailed

    /// Other error
    case other

    public static func from(error: LAError?, biometryType: LABiometryType) -> BiometricAuthenticationError {
        // Using LAError gives false warnings due to a compiler bug.
        // See: https://stackoverflow.com/questions/46455424/touchidlockout-deprecated-in-ios-11-0
        let errorCode = Int32(error?.errorCode ?? 0)
        switch errorCode {
        case kLAErrorUserCancel:
            return cancelledByUser

        case kLAErrorUserFallback:
            return userFallback

        case kLAErrorSystemCancel:
            return cancelledBySystem

        case kLAErrorBiometryNotAvailable:
            return biometryNotAvailable

        default:
            switch biometryType {
            case .faceID:
                return faceIdError(from: errorCode)
            default:
                return touchIdError(from: errorCode)
            }
        }
    }

    private static func faceIdError(from errorCode: Int32) -> BiometricAuthenticationError {
        switch errorCode {
        case kLAErrorAuthenticationFailed:
            return .faceIdFailed

        case kLAErrorPasscodeNotSet:
            return passcodeNotSetFaceId

        case kLAErrorBiometryNotEnrolled:
            return faceIdNotEnrolled

        case kLAErrorBiometryLockout:
            return .faceIdLockedOut

        default:
            return other
        }
    }

    private static func touchIdError(from errorCode: Int32) -> BiometricAuthenticationError {
        switch errorCode {
        case kLAErrorAuthenticationFailed:
            return .touchIdFailed

        case kLAErrorPasscodeNotSet:
            return passcodeNotSetTouchId

        case kLAErrorBiometryNotEnrolled:
            return touchIdNotEnrolled

        case kLAErrorBiometryLockout:
            return .touchIdLockedOut

        default:
            return other
        }
    }

    // MARK: - Error Message

    /// Error message for biometric authentication
    ///
    /// - Returns: error message for authentication
    public func errorMessage() -> String {
        switch self {
        case .cancelledByUser, .userFallback, .cancelledBySystem:
            return biometricCancelMessage

        case .biometryNotAvailable:
            return biometricNotAvailableMessage

        case .passcodeNotSetFaceId:
            return BiometricAuthenticationError.passcodeRequiredMessage(for: .faceID)

        case .passcodeNotSetTouchId:
            return BiometricAuthenticationError.passcodeRequiredMessage(for: .touchID)

        case .faceIdNotEnrolled:
            return BiometricAuthenticationError.notEnrolledMessage(for: .faceID)

        case .touchIdNotEnrolled:
            return BiometricAuthenticationError.notEnrolledMessage(for: .touchID)

        case .faceIdLockedOut:
            return BiometricAuthenticationError.lockoutPasscodeMessage(for: .faceID)

        case .touchIdLockedOut:
            return BiometricAuthenticationError.lockoutPasscodeMessage(for: .touchID)

        case .faceIdFailed:
            return BiometricAuthenticationError.failedMessage(for: .touchID)

        case .touchIdFailed:
            return BiometricAuthenticationError.failedMessage(for: .touchID)

        case .other:
            return ""
        }
    }

    private var biometricCancelMessage: String {
        "Biometric authentication was canceld."
    }

    private var biometricNotAvailableMessage: String {
        "Biometric authentication is not available for this device."
    }

    private static func passcodeRequiredMessage(for biometryType: LABiometryType) -> String {
        let biometryTypeString = biometryType == .faceID ? "Face ID" : "Touch ID"
        return "Please set device passcode to use \(biometryTypeString) for authentication."
    }

    private static func notEnrolledMessage(for biometryType: LABiometryType) -> String {
        let biometryTypeString = biometryType == .faceID ? "Face ID" : "Touch ID"
        return
            """
            \(biometryTypeString) has not been set up on the device.
            Please go to Device Settings -> \(biometryTypeString) & Passcode to set up \(biometryTypeString).
            """
    }

    private static func lockoutPasscodeMessage(for biometryType: LABiometryType) -> String  {
        let biometryTypeString = biometryType == .faceID ? "Face ID" : "Touch ID"
        return
            """
            \(biometryTypeString) is locked due to too many failed attempts.
            Enter your passcode to unlock \(biometryTypeString).
            """
    }

    private static func failedMessage(for biometryType: LABiometryType) -> String {
        let biometryTypeString = biometryType == .faceID ? "Face ID" : "Touch ID"
        let faceOrFingerPrint = biometryType == .faceID ? "face" : "fingerPrint"
        return
            """
            \(biometryTypeString) does not recognize your face.
            Please try again with your enrolled \(faceOrFingerPrint).
            """
    }
}
