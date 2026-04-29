//
//  MainView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI

struct RootView: View {
    @State private var showSignInView = false

    var body: some View {
        NavigationStack {
            if showSignInView {
                AuthenticationView(showSignInView: $showSignInView)
            } else {
                MainView(showSignInView: $showSignInView)
            }
        }
        .onAppear {
            showSignInView = !isUserAuthenticated
        }
    }

    private var isUserAuthenticated: Bool {
        (try? AuthenticationManager.shared.getAuthenticatedUser()) != nil
    }
}

enum NavigationTab {
    case home
    case history
    case food
    case settings
    case workout
}

#Preview {
    RootView()
}
