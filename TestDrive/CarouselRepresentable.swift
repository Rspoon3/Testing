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
        let layoutModel = CarouselLayoutModel(collectionViewWidth: 393, indexPath: $model.currentIndex)
        let layout = CarouselLayout(model: layoutModel)
        let collectionView = MiddleUICollectionView(frame: .zero,
                                                    collectionViewLayout: layout,
                                                    indexPath: $model.currentIndex)
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.backgroundColor = .white
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = model
        collectionView.dataSource = model
        
        model.collectionView = collectionView
        model.registerCell()

        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {}
}

class MiddleUICollectionView: UICollectionView {
    var shouldScrollToMiddle = true
    @Binding var indexPath: IndexPath

    init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout, indexPath: Binding<IndexPath>) {
        _indexPath = indexPath
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard shouldScrollToMiddle else { return }
        let middle = numberOfItems(inSection: 0) / 2
        
        scrollToItem(at: .init(item: middle, section: 0), at: .centeredHorizontally, animated: false)
        indexPath.item = middle
        
        shouldScrollToMiddle = false
    }
}
