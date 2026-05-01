//
//  HeaderLine.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/27/23.
//

import SwiftUI

struct HeaderLine: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hello, World!")
            Divider()
        }
    }
}

struct HeaderLine_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { _ in
                HeaderLine()
            }
            .padding()
        }
    }
}
