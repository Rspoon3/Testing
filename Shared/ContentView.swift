//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine
import PhoneNumberKit

struct ContentView: View {
    @State private var text = "1234567890"
    
    var body: some View {
        PhoneNumberTextField("Phone Number", text: $text)
        Test()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Test: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        PhoneNumberKit.PhoneNumberTextField()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
