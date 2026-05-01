//
//  View+FramePreference.swift
//  Frisbee
//
//  Created by Gray Campbell on 2/19/22.
//  Copyright © 2022 Fetch. All rights reserved.
//

public import SwiftUI

extension View {
    public func framePreference(
        in coordinateSpace: CoordinateSpace
    ) -> some View {
        self.framePreference(FramePreferenceKey.self, in: coordinateSpace)
    }

    public func framePreference<Key: PreferenceKey>(
        _ key: Key.Type,
        in coordinateSpace: CoordinateSpace
    ) -> some View where Key.Value == CGRect {
        self.modifier(
            FrameModifier(
                preferenceKey: key,
                coordinateSpace: coordinateSpace
            )
        )
    }

    public func onFramePreferenceChange(
        perform action: @escaping (CGRect) -> Void
    ) -> some View {
        self.onFramePreferenceChange(FramePreferenceKey.self, perform: action)
    }

    public func onFramePreferenceChange<Key: PreferenceKey>(
        _ key: Key.Type,
        perform action: @escaping (CGRect) -> Void
    ) -> some View where Key.Value == CGRect {
        self.onPreferenceChange(key, perform: action)
    }

    public func onFramePreferenceChange(
        update frame: Binding<CGRect>
    ) -> some View {
        self.onFramePreferenceChange(FramePreferenceKey.self, update: frame)
    }

    public func onFramePreferenceChange<Key: PreferenceKey>(
        _ key: Key.Type,
        update frame: Binding<CGRect>
    ) -> some View where Key.Value == CGRect {
        self.onFramePreferenceChange(key) { frame.wrappedValue = $0 }
    }

    public func onFrameChange(
        in coordinateSpace: CoordinateSpace,
        perform action: @escaping (CGRect) -> Void
    ) -> some View {
        self.framePreference(in: coordinateSpace)
            .onFramePreferenceChange(perform: action)
    }

    public func onFrameChange(
        in coordinateSpace: CoordinateSpace,
        update frame: Binding<CGRect>
    ) -> some View {
        self.framePreference(in: coordinateSpace)
            .onFramePreferenceChange(update: frame)
    }
}

// MARK: - FramePreferenceKey

private struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - FrameModifier

private struct FrameModifier<Key: PreferenceKey>: ViewModifier where Key.Value == CGRect {

    // MARK: Properties

    let preferenceKey: Key.Type
    let coordinateSpace: CoordinateSpace

    // MARK: Body

    func body(content: Content) -> some View {
        content.overlay(self.frameReader)
    }

    // MARK: Frame Reader

    private var frameReader: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: self.preferenceKey,
                    value: geometry.frame(in: self.coordinateSpace)
                )
        }
    }
}
