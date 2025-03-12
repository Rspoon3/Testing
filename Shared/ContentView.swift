//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            ScrollingAvatarBackground()
                .opacity(0.04)
                .ignoresSafeArea()

            VStack {
                AvatarView()
                    .padding(.bottom, 40)

                Text("It's nice to meet you!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title)

                TextField("Username", text: .constant("Ricky"))
                    .textFieldStyle(.roundedBorder)

                TextField("Last Name", text: .constant("Witherspoon"))
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
