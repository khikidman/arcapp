//
//  SettingsViewModel.swift
//  Productivity
//
//  Created by Khi Kidman on 6/2/25.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var authProviders: [AuthProviderOption] = []
    @Published var currentUser: DBUser?
    @Published var isLoadingProfile = false

    func loadSettings() async {
        loadAuthProviders()
        await loadCurrentUser()
    }

    private func loadAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getProviders() {
            authProviders = providers
        }
    }

    private func loadCurrentUser() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
            currentUser = try await UserManager.shared.getUser(userId: authUser.uid)
        } catch {
            if let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() {
                currentUser = DBUser(auth: authUser)
            }
        }
    }

    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }

    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()

        guard let email = authUser.email else {
            throw URLError(.userAuthenticationRequired)
        }

        try await AuthenticationManager.shared.resetPassword(email: email)
    }

    func updateEmail(email: String) async throws {
        try await AuthenticationManager.shared.updateEmail(email: email)
    }

    func updatePassword(password: String) async throws {
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
}
