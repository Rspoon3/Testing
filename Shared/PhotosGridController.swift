//
//  PhotosGridController.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/18/20.
//

import SwiftUI
import Combine

struct PhotoGrid: UIViewControllerRepresentable{
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotoGrid>) -> UINavigationController {
        return UINavigationController(rootViewController: PhotosGridController{
            selectedImage = $0
        })
    }
    
    func updateUIViewController(_ nc: UINavigationController, context: UIViewControllerRepresentableContext<PhotoGrid>) {
    }
}


class PhotosGridController: UIViewController, UICollectionViewDelegate {
    enum Section { case main }
    var dataSource: UICollectionViewDiffableDataSource<Section, URL>! = nil
    var collectionView: UICollectionView! = nil
    var imageSelection: ((UIImage)->Void)!
    let searchController = UISearchController()
    var subscriptions = Set<AnyCancellable>()
    
    init(imageSelection: @escaping (UIImage)->Void){
        super.init(nibName: nil, bundle: nil)
        self.imageSelection = imageSelection
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        configureSearchController()
        fetchURLS()
    }
    
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoGridCell, URL> { (cell, indexPath, url) in
            // Populate the cell with our item description.
            cell.url = url
            cell.showErrorAlert = {
                self.throwAlert(with: $0)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, URL>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: URL) -> UICollectionViewCell? in
            // Return the cell.
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
    }
    
    func updateDataSource(with urls: [URL]){
        var snapshot = NSDiffableDataSourceSnapshot<Section, URL>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(urls)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = dataSource.collectionView(collectionView, cellForItemAt: indexPath) as! PhotoGridCell
        if let image = cell.imageView.image{
            imageSelection(image)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    //MARK: - Helpers
    private func createLayout() -> UICollectionViewLayout {
        // We have three row styles
        // Style 1: 'Full'
        // A full width photo
        // Style 2: 'Main with pair'
        // A 2/3 width photo with two 1/3 width photos stacked vertically
        // Style 3: 'Triplet'
        // Three 1/3 width photos stacked horizontally
        // Full
        let fullPhotoItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(2/3)))
        
        // Main with pair
        let mainItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(2/3),
                heightDimension: .fractionalHeight(1.0)))
        
        let pairItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.5)))
        let trailingGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1.0)),
            subitem: pairItem,
            count: 2)
        
        let mainWithPairGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/9)),
            subitems: [mainItem, trailingGroup])
        
        // Triplet
        let tripletItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1.0)))
        
        let tripletGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(2/9)),
            subitems: [tripletItem, tripletItem, tripletItem])
        
        // Reversed main with pair
        let mainWithPairReversedGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/9)),
            subitems: [trailingGroup, mainItem])
        
        let nestedGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(16/9)),
            subitems: [fullPhotoItem, mainWithPairGroup, tripletGroup, mainWithPairReversedGroup])
        
        let section = NSCollectionLayoutSection(group: nestedGroup)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func throwAlert(with error: Error){
        let ac = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        self.present(ac, animated: true)
    }
    
    private func fetchURLS(){
        UnsplashAPI.fetchRandomPhotoURLs()
            .sink(receiveCompletion: {
                if case .failure(let error) = $0{
                    self.throwAlert(with: error)
                }
            }, receiveValue: { [weak self] urls in
                self?.updateDataSource(with: urls)
            }).store(in: &subscriptions)
    }
    
    //MARK: - Search Controller
    func configureSearchController(){
        let nc        = NotificationCenter.default
        let name      = UISearchTextField.textDidChangeNotification
        let textField = searchController.searchBar.searchTextField
        searchController.searchBar.placeholder = "Search"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        nc.publisher(for: name, object: textField)
            .map { ($0.object as! UISearchTextField).text }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .flatMap{ string in
                UnsplashAPI.searchForPhoto(query: string ?? "nature")
            }
            .sink {
                if case .failure(let error) = $0{
                    self.throwAlert(with: error)
                }
            } receiveValue: { [weak self] urls in
                self?.updateDataSource(with: urls)
            }.store(in: &subscriptions)
    }
}

