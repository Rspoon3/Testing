//
//  LinkPreviewCard.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//

import SwiftUI
import SwiftUI

struct LinkPreviewCard: View {
    let linkItem: LinkItem
    
    var body: some View {
        VStack {
            if let metadata = linkItem.metadata {
                LPLinkViewRepresentable(metadata: metadata)
                    .frame(height: 120)
                    .cornerRadius(8)
            } else {
                ProgressView()
                    .frame(height: 120)
            }
        }
        .frame(width: 150, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
