//
//  AuthenticationViewModel.swift
//  Arc
//
//  Created by Khi Kidman on 3/25/26.
//

import Combine
import Foundation
import AuthenticationServices

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    private let appleSignInCoordinator = SignInAppleCoordinator()
 
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }

    func signInApple() async throws {
        let tokens = try await appleSignInCoordinator.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithApple(tokens: tokens)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
}
