//
//  PatrickHorizontal.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/30/23.
//

import SwiftUI

struct BookReview: Codable {
    var id = UUID()
    var imageTitle: String
    var rating: CGFloat = 1
    var drawingData: Data?
    var createdDate = Date()
}

struct PatrickHorizontal: View {
    @State private var rating: CGFloat = 1.5
    private let bookWidth: CGFloat = 200
    private let bookPadding: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 30) {
                bookDetails
                
                GeometryReader { geo in
                    VStack(spacing: 30) {
                        ForEach(0..<100, id: \.self) { _ in
                            Divider()
                        }
                    }
                }
            }
            
            PKCanvas()
            
            book
        }
    }
    
    var bookDetails: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.headline)
                Divider()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Author")
                        .font(.headline)
                    Divider()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Genre")
                        .font(.headline)
                    Divider()
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pages")
                        .font(.headline)
                    Divider()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Book Type")
                        .font(.headline)
                    Divider()
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Date")
                        .font(.headline)
                    Divider()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("End Date")
                        .font(.headline)
                    Divider()
                }
            }
        }
        .padding(.leading, bookWidth + bookPadding * 2)
    }
    
    var book: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Book I")
                .foregroundColor(.white)
                .frame(minWidth: 100)
                .font(.headline)
                .padding(.all, 8)
                .background(
                    Capsule()
                        .foregroundColor(.gray)
                )
            
            Image("mockingBird")
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
            
            HStack {
                ForEach(1..<6){ i in
                    Image(systemName: star(CGFloat(i)))
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.yellow)
                        .animation(.default, value: rating)
                        .onTapGesture {
                            print(rating, i)
                            if rating == CGFloat(i) {
                                rating = rating - 0.5
                            } else {
                                rating = CGFloat(i)
                            }
                        }
                }
            }
        }
        .frame(width: bookWidth)
        .padding(.all, bookPadding)
        .padding(.bottom, bookPadding)
        .background(Color.white)
        .onTapGesture {
            print("Here")
        }
    }
    
    func star(_ i: CGFloat) -> String {
        if i <= rating {
            return "star.fill"
        } else if i - 0.5 == rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct PatrickHorizontal_Previews: PreviewProvider {
    static var previews: some View {
        PatrickHorizontal()
    }
}
