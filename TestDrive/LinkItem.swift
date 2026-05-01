//
//  LinkItem.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//


import Foundation
import LinkPresentation

struct LinkItem: Identifiable {
    let id = UUID()
    let url: URL
    var metadata: LPLinkMetadata?
}