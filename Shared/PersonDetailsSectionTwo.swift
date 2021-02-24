//
//  PersonDetailsSectionTwo.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import SwiftUI

struct PersonDetailsSectionTwo: View {
    let person: Person
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            HStack{
                Text("Price: ") +
                    Text(person.formattedDiscountedPrice == nil ? person.formattedPrice: person.formattedDiscountedPrice!)
                    .foregroundColor(.red)
                HStack(alignment: .top, spacing: 8){
                    HStack(spacing: -3){
                        Text(Image(systemName: "checkmark"))
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                        Text("prime")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    Text("FREE One-Hour Delivery + FREE Returns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: false)
                }
            }
            
            Text("Fit: ").fontWeight(.semibold) +
                Text("As expected 73%")
            
            Text("Height: ").fontWeight(.semibold) +
                Text("5 ft, 10 in")
            
            Text("Love Language: ")
                .fontWeight(.semibold)
            
            HStack{
                Text(person.loveLanguage[0])
                    .padding(.all, 4)
                    .border(Color.orange)
                
                Text(person.loveLanguage[1])
                    .padding(.all, 4)
                    .foregroundColor(.secondary)
                    .border(Color.secondary)
            }
            HStack{
                Text(person.loveLanguage[2])
                    .padding(.all, 4)
                    .foregroundColor(.secondary)
                    .border(Color.secondary)
                    .lineLimit(1)
                Text(person.loveLanguage[3])
                    .padding(.all, 4)
                    .foregroundColor(.secondary)
                    .border(Color.secondary)
            }
            Text(person.loveLanguage[4])
                .padding(.all, 4)
                .foregroundColor(.secondary)
                .border(Color.secondary)
            
            VStack(alignment: .leading, spacing: 10){
                Text("• has a full time job")
                Text("• no dog yet but is open")
                Text("• learning to love the gym")
                Text("• he is ") + Text("not").italic() + Text(" the father")
            }
            
            Text("Used (1) from $9.95")
                .foregroundColor(.blue)
                .font(.caption)
        }
    }
}

struct PersonDetailsSectionTwo_Previews: PreviewProvider {
    static var previews: some View {
        PersonDetailsSectionTwo(person: .ricky)
            .padding(.horizontal)
    }
}
