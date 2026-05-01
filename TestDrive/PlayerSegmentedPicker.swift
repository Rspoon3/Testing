//
//  PlayerSegmentedPicker.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

struct PlayerSegmentedPicker: View {
    @Namespace private var animation
    let selectedPlayer: Player
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Player.allCases) { player in
                Image(systemName: player.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 30)
                    .padding(.vertical, 6)
                    .background {
                        if selectedPlayer == player {
                            Capsule()
                                .foregroundStyle(Color.white)
                                .matchedGeometryEffect(id: "selected", in: animation)
                        }
                    }
                    .contentShape(Capsule())
                    .animation(.spring(duration: 0.2), value: selectedPlayer)
            }
        }
        .padding(6)
        .background {
            Capsule()
                .foregroundStyle(Color.gray.opacity(0.5))
        }
    }
}


#Preview {
    @Previewable @State var player = Player.computer
    
    VStack {
        Button("Change Player") {
            if player == .computer {
                player = .user
            } else {
                player = .computer
            }
        }
        
        PlayerSegmentedPicker(selectedPlayer: player)
    }
}
