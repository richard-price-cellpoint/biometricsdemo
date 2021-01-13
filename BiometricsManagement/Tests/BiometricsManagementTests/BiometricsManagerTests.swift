@testable import BiometricsManagement
import LocalAuthentication
import XCTest

final class BiometricsManagerTests: XCTestCase {
    func testInitTouchID() {
        let mockContext = LAContextMock()
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        XCTAssertEqual(sut.state, .touchIdAvailableNoUserPermission)
    }

    func testInitFaceID() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        XCTAssertEqual(sut.state, .faceIdAvailableNoUserPermission)
    }

    func testCannotEvaluate() throws {
        let mockContext = LAContextMock()
        mockContext.canEvaluate = false
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        let testError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
        XCTAssertEqual(mockContext.contextError, testError)
        XCTAssertEqual(sut.state, .notAvailable(.biometryNotAvailable))
    }

    func testCannotEvaluateOtherError() throws {
        let mockContext = LAContextMock()
        mockContext.canEvaluate = false
        mockContext.contextError = try? LAError.error(from: 5000)
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        XCTAssertEqual(sut.state, .notAvailable(.other))
    }

    func testTouchIdAvailableNoUserPermission() {
        let mockContext = LAContextMock()
        let mockUserDefaults = UserDefaultsMock()
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        XCTAssertEqual(sut.state, .touchIdAvailableNoUserPermission)
    }

    func testFaceIdAvailableNoUserPermission() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        let mockUserDefaults = UserDefaultsMock()
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        XCTAssertEqual(sut.state, .faceIdAvailableNoUserPermission)
    }

    func testFaceIDAvailableUserEnabled() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        let mockUserDefaults = UserDefaultsMock()
        mockUserDefaults.termsAccepted = true
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        XCTAssertEqual(sut.state, .faceIDAvailableUserEnabled)
    }

    func testFaceIDAvailableUserDisabled() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        mockContext.canEvaluateBio = false
        let mockUserDefaults = UserDefaultsMock()
        mockUserDefaults.termsAccepted = true
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        XCTAssertEqual(sut.state, .faceIDAvailableUserDisabled)
    }

    func testDefaultBiometricsState() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        mockContext.canEvaluateBio = false
        let mockUserDefaults = UserDefaultsMock()
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let testError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
        XCTAssertEqual(mockContext.contextError, testError)
        XCTAssertEqual(sut.state, .notAvailable(.biometryNotAvailable))
    }

    func testDefaultBiometricsStateWithOther() {
        let mockContext = LAContextMock()
        mockContext.biometryType = .faceID
        mockContext.canEvaluateBio = false
        mockContext.contextError = try? LAError.error(from: 5000)
        mockContext.shouldChangeBioError = false
        let mockUserDefaults = UserDefaultsMock()
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let testError = try? LAError.error(from: 5000)
        XCTAssertEqual(mockContext.contextError, testError)
        XCTAssertEqual(sut.state, .notAvailable(.other))
    }

    func testAuthenticateUserBiometryNotAvailable() {
        let mockContext = LAContextMock()
        mockContext.canEvaluate = false
        let sut = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        var error: BiometricAuthenticationError?
        sut.authenticateUser { result in
            if case .failure(let testError) = result {
                error = testError as? BiometricAuthenticationError
            }
        }
        XCTAssertEqual(error, .biometryNotAvailable)
    }

    func testAuthenticateUserPolicyAndSelfNil() {
        let mockContext = LAContextMock()
        var sut: BiometricsManager? = BiometricsManager(
            reason: "Test reason",
            context: mockContext
        )
        var error: BiometricAuthenticationError?
        sut?.authenticateUser {
            if case .failure(let testError) = $0 {
                error = testError as? BiometricAuthenticationError
            }
        }
        XCTAssertEqual(mockContext.laPolicy, .deviceOwnerAuthentication)
        sut = nil
        guard let evaluateReply = mockContext.evaluateReply else {
            XCTFail("Closure should not be nil")
            return
        }
        evaluateReply(true, nil)
        XCTAssertEqual(error, .other)
    }

    func testAuthenticateUserPolicySuccess() {
        let mockContext = LAContextMock()
        let mockUserDefaults = UserDefaultsMock()
        let sut: BiometricsManager = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let expectation = XCTestExpectation(description: "Authenticate user")
        var isSuccess = false
        sut.authenticateUser {
            if case .success = $0 {
                isSuccess = true
                expectation.fulfill()
            }
        }
        guard let evaluateReply = mockContext.evaluateReply else {
            XCTFail("Closure should not be nil")
            return
        }
        evaluateReply(true, nil)
        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(mockUserDefaults.termsAccepted)
        XCTAssertTrue(isSuccess)
    }

    func testAuthenticateUserPolicyFailureNoError() {
        let mockContext = LAContextMock()
        let mockUserDefaults = UserDefaultsMock()
        let sut: BiometricsManager = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let expectation = XCTestExpectation(description: "Authenticate user")
        var error: BiometricAuthenticationError?
        sut.authenticateUser {
            if case .failure(let testError) = $0 {
                error = testError as? BiometricAuthenticationError
                expectation.fulfill()
            }
        }
        guard let evaluateReply = mockContext.evaluateReply else {
            XCTFail("Closure should not be nil")
            return
        }
        evaluateReply(false, nil)
        wait(for: [expectation], timeout: 10.0)
        XCTAssertFalse(mockUserDefaults.termsAccepted)
        XCTAssertEqual(error, .other)
    }

    func testAuthenticateUserPolicyFailureNotLAError() {
        let mockContext = LAContextMock()
        let mockUserDefaults = UserDefaultsMock()
        let sut: BiometricsManager = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let expectation = XCTestExpectation(description: "Authenticate user")
        var error: BiometricAuthenticationError?
        sut.authenticateUser {
            if case .failure(let testError) = $0 {
                error = testError as? BiometricAuthenticationError
                expectation.fulfill()
            }
        }
        guard let evaluateReply = mockContext.evaluateReply else {
            XCTFail("Closure should not be nil")
            return
        }
        evaluateReply(false, BiometricAuthenticationError.faceIdFailed)
        wait(for: [expectation], timeout: 10.0)
        XCTAssertFalse(mockUserDefaults.termsAccepted)
        XCTAssertEqual(error, .faceIdFailed)
        XCTAssertEqual(sut.state, .touchIdAvailableNoUserPermission)
    }

    func testAuthenticateUserPolicyFailureErrorCorrect() throws {
        let mockContext = LAContextMock()
        let mockUserDefaults = UserDefaultsMock()
        let sut: BiometricsManager = BiometricsManager(
            reason: "Test reason",
            context: mockContext,
            userDefaults: mockUserDefaults
        )
        let expectation = XCTestExpectation(description: "Authenticate user")
        var error: BiometricAuthenticationError?
        sut.authenticateUser {
            if case .failure(let testError) = $0 {
                error = testError as? BiometricAuthenticationError
                expectation.fulfill()
            }
        }
        guard let evaluateReply = mockContext.evaluateReply else {
            XCTFail("Closure should not be nil")
            return
        }
        let laError = try? LAError.error(from: kLAErrorBiometryNotAvailable)
        evaluateReply(false, laError)
        wait(for: [expectation], timeout: 10.0)
        XCTAssertFalse(mockUserDefaults.termsAccepted)
        XCTAssertEqual(error, .biometryNotAvailable)
        XCTAssertEqual(sut.state, .touchIdAvailableNoUserPermission)
    }
}
