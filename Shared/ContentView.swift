//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = CarouselModel()
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("TOP")
                Carousel(model: model)
//                    .frame(height: (geo.size.width - 12 * 4) / 2)
                Text("Width: \(geo.size.width)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class CarouselModel: NSObject, ObservableObject, UICollectionViewDelegate, UICollectionViewDataSource {
    let carouselItems = [UIColor.systemRed, .systemBlue, .systemOrange, .systemPink, .systemGray, .systemTeal, .systemGreen]
    private let numberOfCarouselItems = 1_000_000
    private(set) var collectionView: OrthogonalUICollectionView! = nil
    private var cellRegistration: UICollectionView.CellRegistration<TestCell, UIColor>! = nil
    let minScale: CGFloat = 0.8
    let maxScale: CGFloat = 1
    
    
    override init() {
        super.init()
        
        registerCell()
        
        collectionView = OrthogonalUICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() ) {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self else { return nil }
            
            let containerWidth = layoutEnvironment.container.contentSize.width
            let spacing: CGFloat = 12
            let width: CGFloat = containerWidth - spacing * 4
            
            print(containerWidth)

            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width),
                                                   heightDimension: .absolute(width / 2))
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

                    if let cell = self.collectionView.cellForItem(at: item.indexPath) as? TestCell {
                        cell.shadowOpacity(percentage: percentageToMidX)
    //                    cell.scale(clampedScale)
                    }
                    
                    print(self.collectionView.cellForItem(at: item.indexPath))
                    print(item.indexPath)

                    item.transform = CGAffineTransform(scaleX: clampedScale, y: clampedScale)

                    if scale > 0.9 {
//                        self.currentIndex = item.indexPath
                    }
                }
            }

            return section
        }
    }
    
    func registerCell(){
        cellRegistration = UICollectionView.CellRegistration<TestCell, UIColor> { (cell, indexPath, color) in
            cell.configure(with: color, indexPath: indexPath)
            cell.label.text = indexPath.item.formatted()
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
}

struct Carousel: UIViewRepresentable {
    @ObservedObject var model: CarouselModel

    
    func makeUIView(context: Context) -> UICollectionView {
        return model.collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        
    }
}
