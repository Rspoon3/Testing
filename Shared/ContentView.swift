//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let randomAvatarInt = Int.random(in: 1...50)
    
    var body: some View {
        VStack {
            avatarView
                .padding(.bottom, 40)
                .background {
                    ScrollingAvatarBackground()
                        .opacity(0.2)
                        .ignoresSafeArea()
                }
            
            Text("Its nice to meet you!")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)

            TextField("Username", text: .constant("Ricky"))
                .textFieldStyle(.roundedBorder)
            
            TextField("Username", text: .constant("Witherspoon"))
                .textFieldStyle(.roundedBorder)
      
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var avatarView: some View {
        Button {
            
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image("avatar-\(randomAvatarInt)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Image("icon.pencil.edit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(width: 88 + 10, height: 88 + 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 20)
    }
}


#Preview {
    ContentView()
}
