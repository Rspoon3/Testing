//
//  HomeCell.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import SwiftUI

struct HomeCell: View {
    let person: Person
        
    var body: some View {
        VStack(spacing: 10){
            ZStack(alignment: .topLeading){
                
                
                Image(person.images[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 170)
                    .clipped()
                    .background(Color.red)
                
                if person.isBestSeller{
                    Text("Best Seller")
                        .foregroundColor(.white)
                        .padding(.all, 6)
                        .background(
                            Parallelogram(cutBack: false, cutFront: true)
                                .padding(.trailing, -10)
                                .foregroundColor(.orange)
                        )
                }
            }
            Text("\(person.givenName), \(person.age)")
                .font(.title3)
            
            HStack(spacing: 0){
                ForEach(1..<6){ i in
                    ZStack{
                        if Int(person.averageReview) >= i{
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        } else if Bool.random() && (person.averageReview == 4){
                            Image(systemName: "star.leadinghalf.fill")
                                .foregroundColor(.yellow)
                        }
                        Image(systemName: "star")
                            .foregroundColor(.gray)
                    }
                }
                Text(person.formattedReviewCount)
                    .foregroundColor(.blue)
                    .padding(.leading, 5)
            }
            
            HStack{
                if let discounted = person.formattedDiscountedPrice{
                    Text(discounted)
                    Text(person.formattedPrice)
                        .strikethrough()
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(person.formattedPrice)
                    Text("Subscribe & Save!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
       
            HStack(alignment: .top, spacing: 8){
                HStack(spacing: -3){
                    Text(Image(systemName: "checkmark"))
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                    Text("prime")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Text("FREE One-Hour Delivery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Meet ")
                .foregroundColor(.secondary)
                .font(.caption) +
                Text("Today")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct HomeCell_Previews: PreviewProvider {
    static var previews: some View {
        HomeCell(person: .rich)
    }
}

