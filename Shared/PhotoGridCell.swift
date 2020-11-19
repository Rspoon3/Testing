//
//  PhotoGridCell.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/18/20.
//

import UIKit
import Combine

class PhotoGridCell: UICollectionViewCell {
    let imageView = UIImageView()
    var cancellable: AnyCancellable?
    var showErrorAlert: ((Error)->Void)!
    
    var url: URL! {
        didSet {
            cancellable = UnsplashAPI.fetchPhoto(from: url)
                .sink {
                    switch $0{
                    case .finished: break
                    case .failure(let error):
                        self.showErrorAlert(error)
                    }
                } receiveValue: { [weak self] image in
                    self?.imageView.image = image
                }
        }
    }
    
    static let reuseIdentifier = "PhotoGridCellIdentifier"

    
    func setupViews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

enum UnsplashAPI{
    
    //MARK: - Helpers
    static private func createURL(path: String, items: [URLQueryItem]? = nil)-> String{
        var components = URLComponents()
        components.scheme     = "https"
        components.host       = "api.unsplash.com"
        components.path       = path
        components.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "order_by", value: "popular"),
            URLQueryItem(name: "client_id", value: "r9p8IDK3xWfrLnko3cpuRW3Vyed6JNjlU5grSgiB7LI")
        ]
        
        if let items = items{
            components.queryItems?.append(contentsOf: items)
        }
        
        return components.string!
    }
    
    static private func downloadAndDecode<T:Decodable>(_ urlString: String, type: T.Type) -> AnyPublisher<T, Error>{
        guard let url = URL(string: urlString) else{
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func fetchPhoto(from url: URL) -> AnyPublisher<UIImage, URLError>{
        URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data)! }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    static func fetchRandomPhotoURLs() -> AnyPublisher<[URL], Error>{
        let string = createURL(path: "/topics/wallpapers/photos")

        return self.downloadAndDecode(string, type: [UnsplashImageResults].self)
            .map{ results in
                results.compactMap{ result in
                    URL(string: result.urls.small)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    static func searchForPhoto(query: String) -> AnyPublisher<[URL], Error>{
        let item = URLQueryItem(name: "query", value: query)
        let string = createURL(path: "/search/photos", items: [item])

        return self.downloadAndDecode(string, type: UnsplashImageSearchResults.self)
            .map{ search in
                search.results.compactMap{ result in
                    URL(string: result.urls.small)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

struct UnsplashURLs: Decodable{
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashImageResults: Decodable{
    let urls: UnsplashURLs
}

struct UnsplashImageSearchResults: Decodable{
    let results: [UnsplashImageResults]
}




enum NetworkError: LocalizedError{
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The url is invalid"
        }
    }
}
