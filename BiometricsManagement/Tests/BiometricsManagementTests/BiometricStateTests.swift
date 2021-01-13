@testable import BiometricsManagement
import LocalAuthentication
import XCTest

final class BiometricStateTests: XCTestCase {
    func testNotAvailableAssociatedError() {
        let biometricAuthError = BiometricAuthenticationError.cancelledByUser
        let sut = BiometricsState.notAvailable(biometricAuthError)
        if case .notAvailable(let error) = sut {
            XCTAssertEqual(biometricAuthError, error)
        } else {
            XCTFail("Error should be of case notAvailable")
        }
    }
}
