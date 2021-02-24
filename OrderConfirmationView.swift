//
//  OrderConfirmationView.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 2/24/21.
//

import SwiftUI

struct OrderConfirmationView: View {
    let person: Person
    
    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text(Image(systemName: "checkmark"))
                        .fontWeight(.bold)
                        .imageScale(.large)
                    Text("Thank you, your order has been placed!")
                        .font(.title)
                        .padding(.vertical)
                }
                .foregroundColor(.darkGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("An email confirmation has been sent to you.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(person.images[2])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                
                VStack{
                    HStack(alignment: .top){
                        Text("•")
                        Text("\(person.givenName), \(person.age)- 5'10''- Very into \(person.loveLanguage.randomElement()!) -Special delivery will be shipped to you in the ") + Text("Greater Boston area").foregroundColor(.blue) + Text(" by AmazonDating.co")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(spacing: 10){
                        Text("Guaranteed deliver: ").fontWeight(.medium) + Text("Today, by end of day").foregroundColor(.darkGreen)
                        
                        Text("Order Number: \(String(UUID().uuidString.prefix(20)))")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical)
                    
                    Image("icons")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 35)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
                    .foregroundColor(.clear)
                    .shadow(color: .green, radius: 2, x: 0, y: 0)
            )
            
            Image("shareButton")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 42)
        }
        .padding(.horizontal)
    }
}

struct OrderConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        OrderConfirmationView(person: .ricky)
    }
}
