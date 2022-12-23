//
//  CarouselViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/23/22.
//

import UIKit

class CarouselRepresentableViewModel: NSObject, ObservableObject, UICollectionViewDelegate, UICollectionViewDataSource {
    @Published var currentIndex = IndexPath(item: 0, section: 0)
    @Published var height: CGFloat = 100
    let carouselItems = [UIColor.systemRed, .systemBlue, .systemOrange, .systemPink, .systemGray, .systemTeal, .systemGreen]
    private let numberOfCarouselItems = 10//1_000_000
    let minScale: CGFloat = 0.8
    let maxScale: CGFloat = 1
    private var cellRegistration: UICollectionView.CellRegistration<TestCell, UIColor>! = nil
    weak var collectionView: OrthogonalUICollectionView?
    private var timer: Timer?
    let scrollRateInSeconds: TimeInterval = 4
    
    func configureScrollObserver() {
        collectionView?.didStartDragging = { [weak self] in
            self?.stopTimer()
        }
    }
    
    private func stopTimer() {
        print(#function)
        timer?.invalidate()
        timer = nil
    }
    
    func startTimer() {
        print(#function)
        timer = Timer.scheduledTimer(withTimeInterval: scrollRateInSeconds, repeats: true) { [weak self] timer in
            self?.scrollToNextIndex()
        }
    }
    
    private func scrollToNextIndex() {
        if currentIndex.item == numberOfCarouselItems - 1 {
            currentIndex.item = 0
        } else {
            currentIndex.item += 1
        }
        
        collectionView?.scrollToItem(at: currentIndex, at: .centeredHorizontally, animated: true)
    }
    
    func registerCell() {
        cellRegistration = UICollectionView.CellRegistration<TestCell, UIColor> { (cell, indexPath, color) in
            cell.configure(with: color, indexPath: indexPath)
            cell.label.text = indexPath.item.formatted()
        }
    }
    
    func scrollToMiddle() {
        DispatchQueue.main.async {
            self.currentIndex = IndexPath(row: self.numberOfCarouselItems / 2, section: 0)
            self.collectionView?.scrollToItem(at: self.currentIndex, at: .centeredHorizontally, animated: false)
        }
    }
    
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        print(indexPath)
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self else { return nil }
            
            let containerWidth = layoutEnvironment.container.contentSize.width
            let spacing: CGFloat = 12
            let width: CGFloat = containerWidth - spacing * 4
            let height = width / 2
            
            DispatchQueue.main.async {
                self.height = height
            }
            
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width),
                                                   heightDimension: .absolute(height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // Section
            let interGroupSpacing = -(width - (width * self.minScale)) / 2
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = interGroupSpacing + spacing
            
            section.visibleItemsInvalidationHandler = { [weak self] (items, offset, environment) in
                items.forEach { item in
                    guard let self else { return }
                    
                    let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                    let percentageToMidX =  1 - (distanceFromCenter / (item.frame.width + spacing))
                    let scale = ((self.maxScale - self.minScale) * percentageToMidX) + self.minScale
                    let clampedScale = max(self.minScale, scale)
                    
                    if let cell = self.collectionView?.cellForItem(at: item.indexPath) as? TestCell {
                        cell.shadowOpacity(percentage: percentageToMidX)
                    }
                    
                    item.transform = CGAffineTransform(scaleX: clampedScale, y: clampedScale)
                    
                    if scale > 0.9 {
                        DispatchQueue.main.async {
                            self.currentIndex = item.indexPath
                        }
                    }
                }
            }
            
            return section
        }
    }
}
