//
//  ReviewView.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import SwiftUI

struct ReviewView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15){
            HStack{
                Image(systemName: "person")
                    .foregroundColor(.white)
                    .imageScale(.large)
                    .padding(.all, 5)
                    .background(Color.secondary.clipShape(Circle()))
                
                Text(review.name)
            }
            
            HStack(spacing: 0){
                ForEach(1..<6){ i in
                    ZStack{
                        if Int(review.stars) >= i{
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        Image(systemName: "star")
                            .foregroundColor(.gray)
                    }
                }
                Text(review.title)
                    .padding(.leading, 4)
                    .foregroundColor(.blue)
            }
            
            Text("Verified Purchase")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text(review.comment)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView(review: .holly)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
