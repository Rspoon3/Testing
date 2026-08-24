import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Pure-UIKit drop target, bypassing SwiftUI's `dropDestination`/`onDrop` entirely, to isolate
/// whether cross-app URL drops work at the UIKit level at all on this device/OS.
struct DropCollectionView: UIViewRepresentable {
    @Binding var droppedURLs: [URL]

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 320, height: 44)
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.dropDelegate = context.coordinator
        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDropDelegate {
        var parent: DropCollectionView

        init(parent: DropCollectionView) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            max(parent.droppedURLs.count, 1)
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let label = UILabel(frame: cell.contentView.bounds)
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingMiddle

            if parent.droppedURLs.isEmpty {
                label.text = "UIKIT DROP TARGET (drop a URL anywhere here)"
                cell.contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            } else {
                label.text = parent.droppedURLs[indexPath.item].absoluteString
                cell.contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            }
            cell.contentView.addSubview(label)
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
            session.canLoadObjects(ofClass: URL.self)
                || session.hasItemsConforming(toTypeIdentifiers: [UTType.url.identifier, UTType.text.identifier])
        }

        func collectionView(
            _ collectionView: UICollectionView,
            dropSessionDidUpdate session: UIDropSession,
            withDestinationIndexPath destinationIndexPath: IndexPath?
        ) -> UICollectionViewDropProposal {
            print("UIKit dropSessionDidUpdate — hovering")
            return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }

        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
            print("UIKit performDropWith — \(coordinator.items.count) item(s)")
            for item in coordinator.items {
                _ = item.dragItem.itemProvider.loadObject(ofClass: URL.self) { [weak self] url, error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if let url {
                            print("DROPPED (UIKit) \(url.absoluteString)")
                            self.parent.droppedURLs.append(url)
                            collectionView.reloadData()
                        } else {
                            print("UIKit drop failed to load URL: \(String(describing: error))")
                        }
                    }
                }
            }
        }
    }
}
