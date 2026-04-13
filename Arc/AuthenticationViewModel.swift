//
//  AuthenticationViewModel.swift
//  Arc
//
//  Created by Khi Kidman on 3/25/26.
//

import Combine
import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
 
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
}
