//
//  OrdinalFormatStyle.swift
//  Plate-O
//
//  Created by Ricky on 12/3/24.
//

import Foundation

public struct OrdinalFormatStyle: FormatStyle {
    public typealias FormatInput = Int
    public typealias FormatOutput = String

    private var locale: Locale = .current

    public func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = locale
        return formatter.string(for: value) ?? "\(value)"
    }

    public func locale(_ locale: Locale) -> Self {
        var copy = self
        copy.locale = locale
        return copy
    }
}

extension FormatStyle where Self == OrdinalFormatStyle {
    public static var ordinal: OrdinalFormatStyle { OrdinalFormatStyle() }
}
