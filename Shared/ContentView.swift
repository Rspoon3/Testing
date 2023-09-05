//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    @Published var afoAuthCredential: AFOAuthCredential? //objc
    @Published var oAuthCredential: OAuthCredential? //swift
    
    private let storeIdentifier = "storeIdentifier"
    
    // MARK: - OBJC
    
    func setAFOAuthCredential() {
        let mock = AFOAuthCredential(
            accessToken: "accessToken",
            refreshToken: "refreshToken",
            accessExpireDate: "accessExpireDate",
            refreshExpireDate: "refreshExpireDate",
            userId: "userId",
            authSource: "authSource"
        )
        
        AFOAuthCredential.store(
            mock,
            withIdentifier: storeIdentifier
        )
    }
    
    func retrieveAFOAuthCredential() {
        afoAuthCredential = AFOAuthCredential.retrieveCredential(withIdentifier: storeIdentifier)
    }
    
    // MARK: - Swift
    
    func setOAuthCredential() {
        OAuthCredential.store(.mock, withIdentifier: storeIdentifier)
    }
    
    
    func retrieveOAuthCredential() {
        oAuthCredential = OAuthCredential.retrieveCredential(withIdentifier: storeIdentifier)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        Form {
            Section("AFOAuthCredential - Objc"){
                Button("Set Mock") {
                    viewModel.setAFOAuthCredential()
                }
                
                Button("Retrieve Mock") {
                    viewModel.retrieveAFOAuthCredential()
                }
                
                Text("accessToken")
                    .badge(viewModel.afoAuthCredential?.accessToken ?? "nil")
            }
            
            
            
            Section("OAuthCredential - Swift"){
                Button("Set Mock") {
                    viewModel.setOAuthCredential()
                }
                
                Button("Retrieve Mock") {
                    viewModel.retrieveOAuthCredential()
                }
                
                Text("accessToken")
                    .badge(viewModel.oAuthCredential?.accessToken ?? "nil")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
