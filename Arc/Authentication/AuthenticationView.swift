//
//  AuthenticationView.swift
//  Productivity
//
//  Created by Khi Kidman on 5/31/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift


struct AuthenticationView: View {
    
    @State private var authVM = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            Spacer()
            NavigationLink {
                SignInEmailView(showSignInView: $showSignInView)
            } label: {
                Text("Sign In With Email")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.pink, .pink.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                VStack {
                    Divider().background(Color.white)
                }
                Text("or").foregroundStyle(.primary).padding(.horizontal)
                VStack {
                    Divider().background(Color.white)
                }
            }
            .padding(.vertical, 20)
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .standard, state: .normal)) {
                Task {
                    do {
                        try await authVM.signInGoogle()
                        showSignInView = false
                    } catch {
                        
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 5)
                
            Spacer()
        }
        .padding(35)
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(true))
    }
}

