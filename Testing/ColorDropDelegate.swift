//
//  ColorDropDelegate.swift
//  Testing
//
//  Created by Richard Witherspoon on 6/10/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI


struct ColorDropDelegate: DropDelegate {
    @Binding var color: Color

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [UTI.data])
        providers.first?.loadObject(ofClass: UIColor.self, completionHandler: { (data, error) in
            if let uiColor = data as? UIColor{
                self.color = Color(uiColor)
            }
        })
        return true
    }
}
