//
//  SignInAppleHelper.swift
//  Arc
//
//  Created by OpenAI on 5/2/26.
//

import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

struct AppleSignInResult {
    let idToken: String
    let nonce: String
    let fullName: PersonNameComponents?

    var firstName: String? {
        fullName?.givenName
    }

    var lastName: String? {
        fullName?.familyName
    }
}

enum SignInAppleHelper {
    static func signInResult(
        from result: Result<ASAuthorization, any Error>,
        nonce: String?
    ) throws -> AppleSignInResult {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw URLError(.badServerResponse)
            }

            guard let nonce else {
                throw URLError(.userAuthenticationRequired)
            }

            guard
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                throw URLError(.badServerResponse)
            }

            return AppleSignInResult(
                idToken: idTokenString,
                nonce: nonce,
                fullName: appleIDCredential.fullName
            )

        case .failure(let error):
            throw error
        }
    }

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)

            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode).")
            }

            for random in randoms where remainingLength > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
final class SignInAppleCoordinator: NSObject {
    private var continuation: CheckedContinuation<ASAuthorization, any Error>?
    private var currentNonce: String?

    func signIn() async throws -> AppleSignInResult {
        let nonce = SignInAppleHelper.randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = SignInAppleHelper.sha256(nonce)

        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        defer { currentNonce = nil }
        return try SignInAppleHelper.signInResult(from: .success(authorization), nonce: nonce)
    }
}

extension SignInAppleCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            continuation?.resume(returning: authorization)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

extension SignInAppleCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
