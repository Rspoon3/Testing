//
//  CarouselRepresentable.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/23/22.
//

import SwiftUI

struct CarouselRepresentable: UIViewRepresentable {
    @ObservedObject var model: CarouselRepresentableViewModel
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = OrthogonalUICollectionView(frame: .zero,
                                                        collectionViewLayout: model.createLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = model
        collectionView.dataSource = model
        collectionView.alwaysBounceVertical = false
        
        model.collectionView = collectionView
        model.registerCell()

        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
    }
}
