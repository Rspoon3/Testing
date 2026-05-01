//
//  CarouselViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/23/22.
//

import UIKit

class CarouselRepresentableViewModel: NSObject, ObservableObject, UICollectionViewDelegate, UICollectionViewDataSource {
    @Published var currentIndex = IndexPath(item: 0, section: 0)
    private let carouselItems = [UIColor.systemRed, .systemBlue, .systemOrange, .systemPink, .systemGray, .systemTeal, .systemGreen]
    private let numberOfCarouselItems = 1_000_000
    private let minScale: CGFloat = 0.8
    private let maxScale: CGFloat = 1
    private var cellRegistration: UICollectionView.CellRegistration<TestCell, UIColor>! = nil
    weak var collectionView: UICollectionView?
    
    //MARK: - Public Helpers
    
    func registerCell() {
        cellRegistration = UICollectionView.CellRegistration<TestCell, UIColor> { (cell, indexPath, color) in
            cell.configure(indexPath: indexPath)
            cell.label.text = indexPath.item.formatted()
        }
    }

    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item % carouselItems.count
        let item = carouselItems[index]
        
        return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfCarouselItems
    }
    
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        print(indexPath)
    }
}
