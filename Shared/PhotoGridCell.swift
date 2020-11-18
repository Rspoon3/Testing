//
//  PhotoGridCell.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/18/20.
//

import UIKit

class PhotoGridCell: UICollectionViewCell {
    let imageView = UIImageView()
    static let reuseIdentifier = "PhotoGridCellIdentifier"

    
    func setupViews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
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
