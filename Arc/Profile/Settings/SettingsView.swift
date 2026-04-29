//
//  SettingsView.swift
//  Arc
//
//  Created by Codex on 8/2/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = SettingsViewModel()
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Preferences") {
                Label("Account settings coming soon", systemImage: "person.crop.circle")
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Couldn't Sign Out", isPresented: hasErrorMessage) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var hasErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func signOut() {
        do {
            try viewModel.signOut()
            showSignInView = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSignInView: .constant(false))
    }
}
