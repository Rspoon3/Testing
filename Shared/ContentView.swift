//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CheckedGridRepresentable()
    }
}

#Preview {
    ContentView()
}


struct CheckedGridRepresentable: UIViewRepresentable {
    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: Self.createLayout()
    )
    
    static private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let contentSize = layoutEnvironment.container.effectiveContentSize.width
            let itemWidth: CGFloat = 44
            let itemSpacing: CGFloat = 10
            let sidePadding: CGFloat = 10
            
            // Calculate the available width excluding the side padding
            let availableWidth = contentSize - (2 * sidePadding)
            
            // Calculate the number of items per row
            let numberOfItemsPerRow = floor(availableWidth / (itemWidth + itemSpacing))
            
            // Calculate the actual spacing between items based on the remaining space
            let totalItemWidth = numberOfItemsPerRow * itemWidth
            let totalSpacingWidth = (numberOfItemsPerRow - 1) * itemSpacing
            let totalWidth = totalItemWidth + totalSpacingWidth
            let remainingSpace = availableWidth - totalWidth
            let adjustedSpacing = (remainingSpace / (numberOfItemsPerRow - 1)) + itemSpacing

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .fractionalHeight(1.0)
            )
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(44)
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            
            group.interItemSpacing = .fixed(adjustedSpacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            
            // Add 10 points of padding on the left and right sides
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: sidePadding, bottom: 0, trailing: sidePadding)
            
            return section
        })
        
        return layout
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = context.coordinator
        
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) { }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UICollectionViewDelegate {
        var collectionView: UICollectionView?
        private var items = Array(1...1_000).map{ _ in CheckmarkItem() }
        private var dataSource: UICollectionViewDiffableDataSource<Section, CheckmarkItem>! = nil
        private var parent: CheckedGridRepresentable
        
        enum Section { case main }
        
        // MARK: - Initializer
        
        init(_ parent: CheckedGridRepresentable) {
            self.parent = parent
            super.init()
            configureDataSource()
            applyInitialSnapshot()
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // Toggle the value of the tapped item
            items[indexPath.item].value.toggle()
            
            if indexPath.item == 20 {
                // Uncheck the first 10 items before and after the 20th item
                let rangeStart = max(0, indexPath.item - 10)
                let rangeEnd = min(items.count - 1, indexPath.item + 10)
                
                for i in rangeStart..<rangeEnd {
                    // Skip the tapped item itself
                    if i != indexPath.item {
                        items[i].value = false
                    }
                }
            }
            
            // Apply the updated snapshot to refresh the UI
            applyInitialSnapshot()
        }
        
        // MARK: - Public
        
        private func configureDataSource() {
            let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, CheckmarkItem> { (cell, indexPath, item) in
                let hostingConfiguration = UIHostingConfiguration {
                    Image(systemName: item.value ? "checkmark.square" : "square")
                        .resizable()
//                        .contentTransition(.symbolEffect(.replace))
                }.margins(.all, 0)
                
                cell.contentConfiguration = hostingConfiguration
            }
            
            dataSource = UICollectionViewDiffableDataSource<Section, CheckmarkItem>(collectionView: parent.collectionView) {
                (collectionView, indexPath, identifier) -> UICollectionViewCell? in
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
            }
        }
        
        private func applyInitialSnapshot() {
            var snapshot = NSDiffableDataSourceSnapshot<Section, CheckmarkItem>()
            snapshot.appendSections([.main])
            snapshot.appendItems(items)
            
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}

struct CheckmarkItem: Identifiable, Hashable, Equatable, Sendable {
    let id = UUID()
    var value = Bool.random()
}
