@testable import BiometricsManagement
import LocalAuthentication
import XCTest

enum TestError: Error {
    case throwFromFunction
}

extension LAError {
    static func error(from laErrorCode: Int32) throws -> LAError {
        let codeRawValue = LAError.Code.RawValue(laErrorCode)
        guard let errorCode = LAError.Code(rawValue: codeRawValue) else {
            XCTFail("Error Code does not have a rawValue")
            throw TestError.throwFromFunction
        }
        return LAError(errorCode)
    }
}

final class BiometricsAuthenticationErrorFaceIDTests: XCTestCase {
    let biometryTypes: [LABiometryType] = [.faceID, .touchID]

    func testUserCancel() {
        let testError = try? LAError.error(from: kLAErrorUserCancel)
        biometryTypes.forEach{
            let sut = BiometricAuthenticationError.from(error: testError, biometryType: $0)
            XCTAssertEqual(sut, .cancelledByUser)
            XCTAssertEqual(sut.errorMessage(), "Biometric authentication was cancelledd.")
        }
    }

    func testUserFallback() {
        let testError = try? LAError.error(from: kLAErrorUserFallback)
        biometryTypes.forEach{
            let sut = BiometricAuthenticationError.from(error: testError, biometryType: $0)
            XCTAssertEqual(sut, .userFallback)
            XCTAssertEqual(sut.errorMessage(), "Biometric authentication was cancelledd.")
        }
    }

    func testSystemCancel() {
        let testError = try? LAError.error(from: kLAErrorSystemCancel)
        biometryTypes.forEach{
            let sut = BiometricAuthenticationError.from(error: testError, biometryType: $0)
            XCTAssertEqual(sut, .cancelledBySystem)
            XCTAssertEqual(sut.errorMessage(), "Biometric authentication was cancelledd.")
        }
    }

    func testBiometryNotAvailableFaceID() {
        let testError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .faceID)
        XCTAssertEqual(sut, .biometryNotAvailable)
        XCTAssertEqual(sut.errorMessage(), "Biometric authentication is not available for this device.")
    }

    func testBiometryNotAvailableTouchID() {
        let testError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .touchID)
        XCTAssertEqual(sut, .biometryNotAvailable)
        XCTAssertEqual(sut.errorMessage(), "Biometric authentication is not available for this device.")
    }

    func testAuthenticationFailedFaceID() {
        let testError = try? LAError.error(from: kLAErrorAuthenticationFailed)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .faceID)
        XCTAssertEqual(sut, .faceIdFailed)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Face ID does not recognize your face.
            Please try again with your enrolled face.
            """
        )
    }

    func testAuthenticationFailedTouchID() {
        let testError = try? LAError.error(from: kLAErrorAuthenticationFailed)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .touchID)
        XCTAssertEqual(sut, .touchIdFailed)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Touch ID does not recognize your face.
            Please try again with your enrolled fingerprint.
            """
        )
    }

    func testPasscodeNotSetFaceID() {
        let testError = try? LAError.error(from: kLAErrorPasscodeNotSet)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .faceID)
        XCTAssertEqual(sut, .passcodeNotSetFaceId)
        XCTAssertEqual(sut.errorMessage(), "Please set device passcode to use Face ID for authentication.")
    }

    func testPasscodeNotSetTouchID() {
        let testError = try? LAError.error(from: kLAErrorPasscodeNotSet)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .touchID)
        XCTAssertEqual(sut, .passcodeNotSetTouchId)
        XCTAssertEqual(sut.errorMessage(), "Please set device passcode to use Touch ID for authentication.")
    }

    func testBiometryNotEnrolledFaceID() {
        let testError = try? LAError.error(from: kLAErrorBiometryNotEnrolled)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .faceID)
        XCTAssertEqual(sut, .faceIdNotEnrolled)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Face ID has not been set up on the device.
            Please go to Device Settings -> Face ID & Passcode to set up Face ID.
            """
        )
    }

    func testBiometryNotEnrolledTouchID() {
        let testError = try? LAError.error(from: kLAErrorBiometryNotEnrolled)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .touchID)
        XCTAssertEqual(sut, .touchIdNotEnrolled)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Touch ID has not been set up on the device.
            Please go to Device Settings -> Touch ID & Passcode to set up Touch ID.
            """
        )
    }

    func testBiometryLockoutFaceID() {
        let testError = try? LAError.error(from: kLAErrorBiometryLockout)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .faceID)
        XCTAssertEqual(sut, .faceIdLockedOut)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Face ID is locked due to too many failed attempts.
            Enter your passcode to unlock Face ID.
            """
        )
    }

    func testBiometryLockoutTouchID() {
        let testError = try? LAError.error(from: kLAErrorBiometryLockout)
        let sut = BiometricAuthenticationError.from(error: testError, biometryType: .touchID)
        XCTAssertEqual(sut, .touchIdLockedOut)
        XCTAssertEqual(
            sut.errorMessage(),
            """
            Touch ID is locked due to too many failed attempts.
            Enter your passcode to unlock Touch ID.
            """
        )
    }

    func testErrorCode5000() {
        let testError = try? LAError.error(from: 500)
        biometryTypes.forEach{
            let sut = BiometricAuthenticationError.from(error: testError, biometryType: $0)
            XCTAssertEqual(sut, .other)
            XCTAssertTrue(sut.errorMessage().isEmpty)
        }
    }

    func testNoError() {
        biometryTypes.forEach{
            let sut = BiometricAuthenticationError.from(error: nil, biometryType: $0)
            XCTAssertEqual(sut, .other)
        }
    }
}
