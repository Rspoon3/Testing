//
//  SettingsButton.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct SettingsButton: View {
    @State private var isRotating = false
    @Binding var showSettings: Bool
    
    var body: some View {
        Button {
            showSettings.toggle()
        } label: {
            ZStack {
                Image(systemName: "arrowshape.backward")
                    .resizable()
                    .opacity(showSettings ? 1 : 0)
                    .accessibilityHidden(!showSettings)
                    .wiggleEffect()
                
                Image(systemName: "gear")
                    .resizable()
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .opacity(showSettings ? 0 : 1)
                    .accessibilityHidden(showSettings)
            }
            .animation(.default, value: showSettings)
            .frame(width: 30, height: 30)
            .foregroundStyle(Color.white)
            .padding(4)
            .background {
                Circle()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
            }
        }
        .padding(.leading)
        .animation(
            Animation.linear(duration: 20)
                .repeatForever(autoreverses: false),
            value: isRotating
        )
        .onAppear {
            isRotating = true
        }
    }
}


#Preview {
    @Previewable @State var showSettings: Bool = false
    SettingsButton(showSettings: $showSettings)
}

struct WiggleEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.symbolEffect(.wiggle, options: .repeat(.continuous))
        } else {
            content // No wiggle effect for older versions
        }
    }
}

extension View {
    func wiggleEffect() -> some View {
        modifier(WiggleEffectModifier())
    }
}
