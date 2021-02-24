//
//  PersonDetailsSectionOne.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/24/21.
//

import SwiftUI

struct PersonDetailsSectionOne: View {
    let person: Person
    
    var body: some View {
        VStack{
            Image(person.images[4])
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
            
            HStack{
                ForEach(0..<person.images.count, id: \.self){ i in
                    Image(person.images[i])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor( i == 4 ? .orange : .clear)
                        )
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10){
                Image("amazonButtons")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
                    .padding(.top)
                
                Text("\(person.givenName), \(person.age)")
                    .font(.title)
                    .padding(.top)
                
                Text("by") + Text(" Amazon Basics")
                    .foregroundColor(.blue)
                
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
                    Text("Best Seller")
                        .foregroundColor(.white)
                        .padding(.all, 6)
                        .background(
                            Parallelogram(cutBack: false, cutFront: true)
                                .frame(width: 110)
                                .foregroundColor(.orange)
                        )
                    Text("for \"")
                        + Text("hot singles near me")
                        .foregroundColor(.blue)
                        + Text("\"")
                }
                .offset(x: 10, y: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PersonDetailsSectionOne_Previews: PreviewProvider {
    static var previews: some View {
        PersonDetailsSectionOne(person: .ricky)
            .padding(.horizontal)
    }
}
