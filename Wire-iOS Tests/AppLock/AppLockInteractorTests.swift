//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import XCTest
import WireSyncEngine
@testable import Wire
@testable import WireCommonComponents

private final class AppLockInteractorOutputMock: AppLockInteractorOutput {
    
    var authenticationResult: AppLock.AuthenticationResult?
    func authenticationEvaluated(with result: AppLock.AuthenticationResult) {
        authenticationResult = result
    }
    
    var passwordVerificationResult: VerifyPasswordResult?
    func passwordVerified(with result: VerifyPasswordResult?) {
        passwordVerificationResult = result
    }
}

private final class UserSessionMock: UserSessionVerifyPasswordInterface {
    var result: VerifyPasswordResult? = .denied
    func verify(password: String, completion: @escaping (VerifyPasswordResult?) -> Void) {
        completion(result)
    }
}

private final class AppLockMock: AppLock {
    static var authenticationResult: AuthenticationResult = .granted

    override final class func evaluateAuthentication(description: String, with callback: @escaping (AuthenticationResult) -> Void) {
        callback(authenticationResult)
    }
    
    static var didPersistBiometrics: Bool = false
    override final class func persistBiometrics() {
        didPersistBiometrics = true
    }
}

final class AppLockInteractorTests: XCTestCase {
    var sut: AppLockInteractor!
    private var appLockInteractorOutputMock: AppLockInteractorOutputMock!
    private var userSessionMock: UserSessionMock!
    
    override func setUp() {
        super.setUp()
        appLockInteractorOutputMock = AppLockInteractorOutputMock()
        userSessionMock = UserSessionMock()
        sut = AppLockInteractor()
        sut._userSession = userSessionMock
        sut.output = appLockInteractorOutputMock
        sut.appLock = AppLockMock.self
    }
    
    override func tearDown() {
        appLockInteractorOutputMock = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatIsTimeoutReachedReturnsFalseIfTimeoutNotReached() {
        //given
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: false, forceAppLock: false, appLockTimeout: 900)
        AppLock.isActive = true
        AppLock.lastUnlockedDate = Date(timeIntervalSinceNow: -Double(AppLock.rules.appLockTimeout)-100)
        
        //when/then
        XCTAssertTrue(sut.isLockTimeoutReached)
    }
    
    func testThatIsTimeoutReachedReturnsTrueIfTimeoutReached() {
        //given
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: false, forceAppLock: false, appLockTimeout: 900)
        AppLock.isActive = true
        AppLock.lastUnlockedDate = Date(timeIntervalSinceNow: -10)
        
        //when/then
        XCTAssertFalse(sut.isLockTimeoutReached)
    }
    
    func testThatEvaluateAuthenticationCompletesWithCorrectResult() {
        //given
        let queue = DispatchQueue(label: "Evaluate authentication test queue", qos: .background)
        sut.dispatchQueue = queue
        AppLockMock.authenticationResult = .granted
        appLockInteractorOutputMock.authenticationResult = nil
        let expectation = XCTestExpectation(description: "evaluate authentication")

        //when
        sut.evaluateAuthentication(description: "")

        //then
        queue.async {
            XCTAssertNotNil(self.appLockInteractorOutputMock.authenticationResult)
            XCTAssertEqual(self.appLockInteractorOutputMock.authenticationResult, AppLockMock.authenticationResult)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThatItNotifiesOutputWhenPasswordWasVerified() {
        //given
        let queue = DispatchQueue(label: "Verify password test queue", qos: .background)
        sut.dispatchQueue = queue
        userSessionMock.result = .denied
        appLockInteractorOutputMock.passwordVerificationResult = nil
        let expectation = XCTestExpectation(description: "verify password")
        
        //when
        sut.verify(password: "")
        
        //then
        queue.async {
            XCTAssertNotNil(self.appLockInteractorOutputMock.passwordVerificationResult)
            XCTAssertEqual(self.appLockInteractorOutputMock.passwordVerificationResult, VerifyPasswordResult.denied)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThatItPersistsBiometricsWhenPasswordIsValid() {
        //given
        userSessionMock.result = .validated

        //when
        sut.verify(password: "")
        
        //then
        XCTAssertTrue(AppLockMock.didPersistBiometrics)
    }
    
    func testThatItDoesntPersistBiometricsWhenPasswordIsInvalid() {
        //given
        userSessionMock.result = .denied
        
        //when
        sut.verify(password: "")

        //then
        XCTAssertFalse(AppLockMock.didPersistBiometrics)
    }
}