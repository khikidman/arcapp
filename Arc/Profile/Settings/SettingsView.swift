//
//  SettingsView.swift
//  Arc
//
//  Created by Codex on 8/2/25.
//

import SwiftUI

struct SettingsView: View {
    private enum WeightUnit: String, CaseIterable, Identifiable {
        case pounds = "lb"
        case kilograms = "kg"

        var id: String { rawValue }
    }

    private enum AppearanceMode: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }
    }

    @Binding var showSignInView: Bool
    @StateObject private var viewModel = SettingsViewModel()
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isResettingPassword = false

    @AppStorage("settings.weightUnit") private var weightUnit = WeightUnit.pounds.rawValue
    @AppStorage("settings.defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("settings.showPreviousSetValues") private var showPreviousSetValues = true
    @AppStorage("settings.autoStartWorkoutTimer") private var autoStartWorkoutTimer = true
    @AppStorage("settings.appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        List {
            profileSection
            accountSection
            workoutPreferencesSection
            appPreferencesSection
            dataSection
            premiumSection
            dangerZoneSection

            Section {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.loadSettings()
        }
        .alert("Settings Error", isPresented: hasErrorMessage) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .alert("Settings Updated", isPresented: hasSuccessMessage) {
            Button("OK", role: .cancel) {
                successMessage = nil
            }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)

                    if let email = viewModel.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // TODO(settings): Add an edit profile screen with Firestore writes and photo upload.
            disabledRow("Edit Profile", systemImage: "pencil", detail: "Not connected")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            LabeledContent("Sign-in Providers", value: providerSummary)

            Button {
                resetPassword()
            } label: {
                if isResettingPassword {
                    ProgressView()
                } else {
                    Label("Reset Password", systemImage: "key")
                }
            }
            .disabled(isResettingPassword || !canResetPassword)

            // TODO(settings): Add forms that collect and validate new credentials before calling the view model.
            disabledRow("Update Email", systemImage: "envelope", detail: "Needs form")
            disabledRow("Update Password", systemImage: "lock", detail: "Needs form")
        }
    }

    private var workoutPreferencesSection: some View {
        Section("Workout Preferences") {
            Picker("Weight Unit", selection: $weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit.rawValue)
                }
            }

            Stepper(value: $defaultRestSeconds, in: 0...600, step: 15) {
                LabeledContent("Default Rest Timer", value: restTimerText)
            }

            Toggle("Show Previous Set Values", isOn: $showPreviousSetValues)
            Toggle("Auto-start Workout Timer", isOn: $autoStartWorkoutTimer)

            // TODO(settings): Persist these preferences to Firestore once settings sync is added.
            disabledRow("Default Set Type", systemImage: "checklist", detail: "Not configured")
        }
    }

    private var appPreferencesSection: some View {
        Section("App Preferences") {
            Picker("Appearance", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }

            Toggle("Haptics", isOn: $hapticsEnabled)

            // TODO(settings): Add notification permission handling and workout reminder scheduling.
            disabledRow("Notifications", systemImage: "bell", detail: "Needs permissions")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            LabeledContent("Sync Status", value: syncStatusText)

            // TODO(settings): Build export and local cache flows after workout sync is finalized.
            disabledRow("Export Workout History", systemImage: "square.and.arrow.up", detail: "Not built")
            disabledRow("Clear Local Cache", systemImage: "externaldrive.badge.xmark", detail: "Not built")
        }
    }

    private var premiumSection: some View {
        Section("Premium") {
            LabeledContent("Current Plan", value: currentPlanText)

            // TODO(settings): Connect to StoreKit or the billing provider used for subscriptions.
            disabledRow("Manage Subscription", systemImage: "creditcard", detail: "Not connected")
        }
    }

    private var dangerZoneSection: some View {
        Section("Danger Zone") {
            // TODO(settings): Add confirmation dialogs and backend deletes before enabling either action.
            disabledRow("Delete Workout History", systemImage: "trash", detail: "Needs confirmation")
            disabledRow("Delete Account", systemImage: "person.crop.circle.badge.xmark", detail: "Needs backend flow")
        }
    }

    private var displayName: String {
        let firstName = viewModel.currentUser?.firstName ?? ""
        let lastName = viewModel.currentUser?.lastName ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)

        if !fullName.isEmpty {
            return fullName
        }

        return viewModel.currentUser?.email ?? "Arc User"
    }

    private var providerSummary: String {
        if viewModel.authProviders.isEmpty {
            return "Unknown"
        }

        return viewModel.authProviders
            .map { provider in
                switch provider {
                case .email:
                    return "Email"
                case .google:
                    return "Google"
                }
            }
            .joined(separator: ", ")
    }

    private var canResetPassword: Bool {
        viewModel.authProviders.contains(.email) && viewModel.currentUser?.email != nil
    }

    private var restTimerText: String {
        if defaultRestSeconds == 0 {
            return "Off"
        }

        let minutes = defaultRestSeconds / 60
        let seconds = defaultRestSeconds % 60

        if minutes == 0 {
            return "\(seconds)s"
        }

        if seconds == 0 {
            return "\(minutes)m"
        }

        return "\(minutes)m \(seconds)s"
    }

    private var syncStatusText: String {
        viewModel.currentUser == nil ? "Signed out" : "Signed in"
    }

    private var currentPlanText: String {
        viewModel.currentUser?.isPremium == true ? "Premium" : "Free"
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

    private var hasSuccessMessage: Binding<Bool> {
        Binding(
            get: { successMessage != nil },
            set: { isPresented in
                if !isPresented {
                    successMessage = nil
                }
            }
        )
    }

    private func disabledRow(_ title: String, systemImage: String, detail: String) -> some View {
        LabeledContent {
            Text(detail)
                .foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: systemImage)
        }
        .disabled(true)
    }

    private func resetPassword() {
        isResettingPassword = true

        Task {
            defer { isResettingPassword = false }

            do {
                try await viewModel.resetPassword()
                successMessage = "A password reset email has been sent."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
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
