//
//  PersonDetailsView.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import SwiftUI

struct PersonDetailsView: View {
    let person: Person
    
    var body: some View {
        ScrollView{
            PersonDetailsSectionOne(person: person)

            Divider()
                .padding(.vertical)

            PersonDetailsSectionTwo(person: person)
                .layoutPriority(2)

            Divider()
                .padding(.vertical)
            
            CustomerReviewsHeader(person: person)
            
            Divider()
                .padding(.vertical)
            
            ForEach(person.reviews){ review in
                ReviewView(review: review)
                
                if review != person.reviews.last{
                    Divider()
                        .padding(.bottom)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PersonDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PersonDetailsView(person: .ricky)
    }
}
