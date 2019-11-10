//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import LBTATools



var movies : [Movie] = [
    .init(title: "Star Wars Episode I", subtitle: "The Phantom Menace", posterID: "starWars1", details : "The Trade federation upsets order and disrupts peace in the Galactic Republic by blockading the planet Naboo in preparation for a full-scale invasion. The Republic's leader, Supreme Chancellor Valorum, dispatches Jedi Master Qui-Gon Jinn and his apprentice, Obi-Wan Kenobi, to negotiate with Trade Federation Viceroy Nute Gunray. Darth Sidious, a Sith Lord and the Trade Federation's secret benefactor, orders the Viceroy to kill the Jedi and begin their invasion with an army of battle droids. The Jedi escape and flee to Naboo. During the invasion, Qui-Gon saves the life of a clumsy Gungan outcast, Jar Jar Binks, from being run over by a droid transport. Indebted to Qui-Gon, Jar Jar leads the Jedi to Otoh Gunga, an underwater city of Naboo. The Jedi try to persuade the Gungan leader, Boss Nass, to help the planet's surface dwellers, but are unsuccessful. However, the Jedi manage to obtain Jar Jar's guidance and underwater transport to Theed, the capital city of Naboo; they narrowly avoid getting eaten by sea monsters on the way. They rescue Naboo's queen, Padmé Amidala, and escape from the blockaded planet on her Royal Starship, intending to reach the Republic capital planet of Coruscant.", releaseDate : "May 19, 1999", rating: 84),
    
    
    
    
    .init(title: "Star Wars Episode II", subtitle: "The Attack of the Clones", posterID: "starWars2"),
    .init(title: "Star Wars Episode III", subtitle: "The Revenge of the Sith", posterID: "starWars3"),
    .init(title: "Star Wars Episode IV", subtitle: "A New Hope", posterID: "starWars4"),
    .init(title: "Star Wars Episode V", subtitle: "The Empire Strikes Back", posterID: "starWars5"),
    .init(title: "Star Wars Episode VI", subtitle: "Return of the Jedi", posterID: "starWars6"),
    .init(title: "Star Wars Episode VII", subtitle: "The Force Awakens", posterID: "starWars7"),
    .init(title: "Star Wars Episode VIII", subtitle: "The Last Jedi", posterID: "starWars8"),
    .init(title: "Star Wars Episode XI", subtitle: "The Rise of Skywalker", posterID: "starWars9"),
]


struct Movie : Identifiable{
    var id = UUID()
    var title: String
    var subtitle : String
    var posterID : String
    var details = ""
    var releaseDate = ""
    var rating = 0
    var director = "George Lucas"
    var isFavorite = true
}



struct ContentView: View {
    
    var body: some View {
        NavigationView {
            List(movies){ movie in
                NavigationLink(destination: MovieDetails(movie: movie)) {
                    MovieView(movie: movie)
                }
            }.navigationBarTitle("Star Wars")
        }
    }
}

struct MovieView : View{
    let movie : Movie
    
    var body : some View{
        VStack{
            HStack(alignment : .top){
                Image(movie.posterID)
                    .resizable()
                    .cornerRadius(10)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100)
                VStack(alignment: .leading){
                    Text(movie.title)
                        .font(.title)
                    Text(movie.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}



struct MovieDetails : View{
    var movie : Movie
    @State var isFavorite = true
    
    var body : some View{
        GeometryReader{ geo in
            ZStack(alignment: .topLeading){
                Image(self.movie.posterID)
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width)
                    .blur(radius: 25)
                VStack(alignment: .leading, spacing: 8){
                    Text(self.movie.title)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(self.movie.subtitle)
                        .foregroundColor(Color.white)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Directed by: \(self.movie.director)")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 20)
                    Image(systemName: "star.fill")
                        .resizable()
                        .foregroundColor(self.isFavorite ? .yellow : .gray)
                        .frame(width: 30, height: 30)
                        .padding(.top)
                        .onTapGesture {
                            self.isFavorite.toggle()
                    }
                    Text(self.movie.details)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    Spacer()
                    Text("Cast")
                    .foregroundColor(.white)
                    .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 50) {
                            ForEach(1...8, id: \.self) { num in
                                Image("actor\(num)")
                                    .resizable()
                                    .cornerRadius(10)
                                    .clipShape(Circle())
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                            }
                        }
                    }.padding(.leading)
                }.padding()
                
            }
        }
    }
}

struct MyCircle : View{
    let animationDuration : Double
    let conic : AngularGradient
    @Binding var trimAmount : CGFloat
    
    var body: some View{
        Circle()
            .trim(from: 0, to: trimAmount)
            .stroke(self.conic, style: .init(lineWidth: 6, lineCap: .round))
            .animation(Animation.easeOut(duration: self.animationDuration).repeatForever())
            .padding()
            .onAppear{
                self.trimAmount = 1
        }
    }
}

struct UsingState : View{
    @State private var trimAmount : CGFloat = 0
    let duration : Double = 3
    let conic = AngularGradient(gradient: Gradient(colors: [.init(.systemRed), .init(.systemYellow),.init(.systemGreen)]), center: .center, angle: .degrees(0))
    
    var body : some View{
        MyCircle(animationDuration: duration, conic: conic, trimAmount: $trimAmount)
    }
}
    

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        //MovieDetails(movie: movies[0])
        //ContentView()
        UsingState()
    }
}




























//struct ContentView: View {
//    // 1.
//    @State private var currentPosition: CGSize = .zero
//    @State private var newPosition: CGSize = .zero
//
//    var body: some View {
//        // 2.
//        Circle()
//            .frame(width: 100, height: 100)
//            .foregroundColor(Color.red)
//            .offset(x: self.currentPosition.width, y: self.currentPosition.height)
//            // 3.
//            .gesture(DragGesture()
//                .onChanged { value in
//                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
//            }   // 4.
//                .onEnded { value in
//                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
//                    print(self.newPosition.width)
//                    self.newPosition = self.currentPosition
//                }
//        )
//    }
//}






class PhotoGridCell: LBTAListCell<String> {
    
    override var item: String! {
        didSet {
            label.text = item!
        }
    }
    
    let label = UILabel(text: "test")
    
    override func setupViews() {
        backgroundColor = .systemBlue
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        addSubview(label)
        label.centerInSuperview()
    }
}

class PhotosGridController: LBTAListController<PhotoGridCell, String>, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0...200 {
            self.items.append("\(i)")
        }
    }
    
    let cellSpacing: CGFloat = 4
    var half = 0
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if (indexPath.item == 0 || indexPath.item == 15) {
            let width = (view.frame.width - 2 * cellSpacing)
            return .init(width: width, height: width)
        }
        
        if (indexPath.item == 7 || indexPath.item == 8 ) {
            let width = (view.frame.width - 3 * cellSpacing) / 2
            return .init(width: width, height: width)
        }
        
        if (indexPath.item == 16) {
            let height = (view.frame.width - 4 * cellSpacing) / 3
            let width = height * 2 + cellSpacing
            return .init(width: width, height: height)
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
