//
//  TestCell.swift
//  UIKitTesting
//
//  Created by Richard Witherspoon on 12/9/22.
//

import UIKit

class TestCell: UICollectionViewCell {
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let cornerRadius: CGFloat = 8
    let label = UILabel()
 
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        containerView.layer.shadowRadius = 5
        containerView.layer.shadowOffset = .init(width: 0, height: 9)
        containerView.layer.shouldRasterize = true
        containerView.layer.rasterizationScale = UIScreen.main.scale
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = cornerRadius

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(indexPath: IndexPath) {
        let i = indexPath.item.isMultiple(of: 2) ? "carousel_B-new-size" : "dog"
        imageView.image = .init(named: i)
    }
    
    func shadowOpacity(percentage: Double) {
        containerView.layer.shadowOpacity = Float(percentage)
    }
}
