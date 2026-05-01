//
//  Patrick.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/30/23.
//

import SwiftUI


struct Patrick: View {
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .imageTitleAlignmentGuide)) {
            blueBox
            
            HStack(alignment: .top, spacing: 0) {
                book
                bookDetails
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .layoutPriority(1)
        }
//        .overlay {
//            PKCanvas()
//        }
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
        .alignmentGuide(.imageTitleAlignmentGuide) { context in
            context[.bottom]
        }
    }
    
    var blueBox: some View {
        VStack(spacing: 30) {
            ForEach(0..<200, id: \.self) { _ in
                Divider()
            }
        }
        .alignmentGuide(.imageTitleAlignmentGuide) { context in
            context[.top] - 30
        }
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
                .frame(height: 300)
                .cornerRadius(8)
            
            HStack {
                Image(systemName: "star.fill")
                Image(systemName: "star.fill")
                Image(systemName: "star.fill")
                Image(systemName: "star.fill")
                Image(systemName: "star.fill")
            }
            .font(.title)
            .symbolRenderingMode(.multicolor)
        }
        .padding()
        .background(Color.white)
    }
}

struct Patrick_Previews: PreviewProvider {
    static var previews: some View {
        Patrick()
    }
}

extension VerticalAlignment {
    /// A custom alignment for image titles.
    private struct ImageTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default to bottom alignment if no guides are set.
            context[VerticalAlignment.top]
        }
    }
    
    /// A guide for aligning titles.
    static let imageTitleAlignmentGuide = VerticalAlignment(
        ImageTitleAlignment.self
    )
}
