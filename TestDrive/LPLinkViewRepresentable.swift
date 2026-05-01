//
//  LPLinkViewRepresentable.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//



import SwiftUI
import LinkPresentation

struct LPLinkViewRepresentable: UIViewRepresentable {
    let metadata: LPLinkMetadata
    
    func makeUIView(context: Context) -> LPLinkView {
        return LPLinkView(metadata: metadata)
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        uiView.metadata = metadata
    }
}
