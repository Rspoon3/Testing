//
//  PurchaseScreen.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 2/24/21.
//

import SwiftUI

struct PurchaseScreen: View {
    let person: Person
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading){
                HStack{
                    Text("1    Shipping Address")
                        .font(.headline)
                    Spacer()
                    Text("Home, Greater Boston Area")
                        .foregroundColor(.secondary)
                }
                Divider()
                HStack{
                    Text("2    Payment Method")
                        .font(.headline)
                    Spacer()
                    Text("Amazon Gift Card Balance")
                        .foregroundColor(.secondary)
                }
                Divider()
                Text("3    Review items and shipping")
                    .font(.headline)
            }
            .padding(.bottom)
            
            VStack(alignment: .leading){
                Text("Guaranteed delivery date: Today")
                    .font(.title2)
                    .foregroundColor(.darkGreen)
                Text("Items shipped from AmazonDating.co")
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top){
                    Image(person.images[5])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                    
                    VStack(alignment: .leading, spacing: 20){
                        Text("\(person.givenName), \(person.age) -5'10'' - very into \(person.loveLanguage[3])")
                        HStack(spacing: -3){
                            if let discount = person.formattedDiscountedPrice{
                                Text(person.formattedPrice)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Text(discount)
                                    .padding(.horizontal, 8)
                            } else {
                                Text(person.formattedPrice)
                                    .padding(.horizontal, 8)
                            }
                            
                            Text(Image(systemName: "checkmark"))
                                .foregroundColor(.orange)
                                .fontWeight(.bold)
                            Text("prime")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                        }
                        
                        Text("Sold by: AmazonDating.co Services, Inc.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text("In Stock.")
                            .foregroundColor(.darkGreen)
                            .font(.caption)
                    }
                }
                
                DeliveryOptions()
                .padding(.vertical)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder()
                    .foregroundColor(.secondary)
            )
            
            VStack{
                Image("placeOrder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack(alignment: .leading){
                    Text("Order total: \(person.formattedDiscountedPrice == nil ? person.formattedPrice : person.formattedDiscountedPrice!)")
                        .foregroundColor(.red)
                        .font(.headline)
                    Text("By placing your order, you agree to Amazon.com's privacy notice, conditions of use and all of the terms.")
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder()
                    .foregroundColor(.secondary)
            )
        }
        .padding(.horizontal)
    }
}

struct PurchaseScreen_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseScreen(person: .ricky)
    }
}
