//
//  IdentafiableItem.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/4/25.
//

import Foundation

struct IdentafiableItem<T>: Identifiable {
    let id = UUID()
    let item: T
}
