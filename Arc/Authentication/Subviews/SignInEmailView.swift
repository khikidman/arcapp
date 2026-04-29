//
//  SignInEmailView.swift
//  Arc
//
//  Created by Khi Kidman on 5/31/25.
//

import SwiftUI

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        
        VStack {
            Spacer()
            TextField("", text: $viewModel.email, prompt: Text("your.email.com"))
                .textFieldStyle(.plain)
                .foregroundStyle(.gray)
                .padding(16)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .frame(height: 5)
                    .foregroundStyle(LinearGradient(colors: [.pink, .pink.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    .offset(y: 24)
                )
            
            SecureField("password", text: $viewModel.password)
                .padding(16)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .frame(height: 5)
                    .foregroundStyle(LinearGradient(colors: [.pink, .pink.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    .offset(y: 24)
                )
            
            Button {
                Task {
                    do {
                        try await viewModel.signUp()
                        showSignInView = false
                        return
                    } catch {
                        print(error)
                    }
                    
                    do {
                        try await viewModel.signIn()
                        showSignInView = false
                        return
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.pink, .pink.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 48)
            
            Spacer()
            Spacer()
                
        }
        
        .padding(35)
        .navigationTitle("Sign In With Email")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignInEmailView(showSignInView: .constant(true))
    }
}
