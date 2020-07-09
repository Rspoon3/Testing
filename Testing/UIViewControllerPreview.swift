//
//  UIViewControllerPreview.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/8/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI


public struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    public init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    // MARK: - UIViewControllerRepresentable
    public func makeUIViewController(context: Context) -> ViewController {
        viewController
    }

    public func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<UIViewControllerPreview<ViewController>>) {
        return
    }
}

