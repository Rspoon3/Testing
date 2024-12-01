//
//  BackDeployedMatchedTransitionSource.swift
//  MathFlashCore
//
//  Created by Ricky on 10/27/24.
//

import SwiftUI

public extension View {
    /// A back deployed version of `matchedTransitionSource`.
    @available(iOS, deprecated: 18, obsoleted: 18, message: "This extension can be removed once iOS 18 is the minimum deployment target.")
    nonisolated func backDeployedMatchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            return self
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            return self
        }
    }
    
    /// A back deployed version of `navigationTransition`.
    @available(iOS, deprecated: 18, obsoleted: 18, message: "This extension can be removed once iOS 18 is the minimum deployment target.")
    nonisolated func backDeployedZoomNavigationTransition(sourceID: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            return self
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            return self
        }
    }
}
