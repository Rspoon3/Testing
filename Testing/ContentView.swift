//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import LBTATools

struct ContentView: View {
    @State private var show = false
    var body: some View {
        NavigationView {
            Button(action: {
                self.show.toggle()
            }) {
                Text("See All")
            }.sheet(isPresented: $show) {
                PhotosGridVC()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





class PhotoGridCell: LBTAListCell<String> {
    
    override var item: String! {
        didSet {
            imageView.image = UIImage(named: item)
        }
    }
    
    let imageView = UIImageView(image: UIImage(named: "avatar1"), contentMode: .scaleAspectFill)
    
    override func setupViews() {
        backgroundColor = .yellow
    }
}

class PhotosGridController: LBTAListController<PhotoGridCell, String>, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .lightGray
        
        self.items = ["avatar1", "story_photo1", "story_photo2", "avatar1", "avatar1", "story_photo1", "story_photo2", "avatar1"]
    }
    
    let cellSpacing: CGFloat = 4
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if self.items.count > 4 {
            let width = (view.frame.width - 3 * cellSpacing) / 2
            return .init(width: width, height: width)
        }
        
        let width = (view.frame.width - 4 * cellSpacing) / 3
        
        return .init(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: cellSpacing, bottom: 0, right: cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row)
        self.items.remove(at: indexPath.row)
    }
    
}

struct PhotosGridVC: UIViewControllerRepresentable {
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotosGridVC>) -> UIViewController {
        return PhotosGridController()
    }
    
    func updateUIViewController(_ uiViewController: PhotosGridVC.UIViewControllerType, context: UIViewControllerRepresentableContext<PhotosGridVC>) {
    }
}
