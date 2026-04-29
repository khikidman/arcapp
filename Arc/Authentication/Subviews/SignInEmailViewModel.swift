//
//  SignInEmailViewModel.swift
//
//  Arc
//
//  Created by Khi Kidman on 6/2/25.
//

import Combine
import Foundation

@MainActor
final class SignInEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("Invalid username or password")
            return
        }

        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("Invalid username or password")
            return
        }

        
        let authDataResult = try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }
    
}

