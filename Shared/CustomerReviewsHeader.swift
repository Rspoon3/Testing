//
//  CustomerReviewsHeader.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/24/21.
//

import SwiftUI

struct CustomerReviewsHeader: View {
    let person: Person
    
    var formattedReviews: String{
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let value = numberFormatter.string(from: NSNumber(value: person.averageReview))
        return "\(value ?? "0") out of 5"
    }
    
    func rectangleWidth(i: Int)-> CGFloat{
        if i == 1{
            return UIScreen.main.bounds.width * 0.5
        } else if i == 2{
            return UIScreen.main.bounds.width * 0.1
        } else if i == 4{
            return 10
        } else {
            return 0
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Customer reviews")
                .font(.title2)
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
                Text(formattedReviews)
                    .foregroundColor(.blue)
                    .padding(.leading, 5)
            }
            Text("\(person.formattedReviewCount) customer ratings")
                .foregroundColor(.secondary)
                .font(.caption)
            
            ForEach(1..<6){ i in
                HStack{
                    Text("\(abs(i - 6)) star")
                        .frame(width: 50, alignment: .leading)
                        .foregroundColor( rectangleWidth(i: i) > 0 ? .blue : .primary)
                    ZStack{
                        Rectangle()
                            .foregroundColor(Color(.systemGray5))
                            Rectangle()
                                .foregroundColor(.yellow)
                                .frame(width: rectangleWidth(i: i))
                                .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .border(Color(.systemGray2))
                    .frame(height: 20)
                    if i == 1{
                        Text("88%")
                            .frame(width: 40)
                            .foregroundColor(.blue)
                    } else if i == 2 {
                        Text("10%")
                            .frame(width: 40)
                            .foregroundColor(.blue)
                    } else {
                        Text(i == 4 ? "2%" : "0%")
                            .frame(width: 40)
                            .foregroundColor(i == 4 ? .blue : .primary)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct CustomerReviewsHeader_Previews: PreviewProvider {
    static var previews: some View {
        CustomerReviewsHeader(person: .ricky)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
