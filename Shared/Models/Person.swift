//
//  Person.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/23/21.
//

import Foundation

struct Person: Identifiable{
    let givenName: String
    let age: Int
    let reviews: [Review]
    private let reviewCount: Int
    let averageReview: Double
    let isPrimeEligible: Bool
    let isSubscribeAndSave: Bool
    private let price: Double
    private let discountedPrice: Double?
    let images: [String]
    let isBestSeller: Bool
    let id = UUID()
    let loveLanguage: [String]
    
    private var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    var formattedPrice: String{
        currencyFormatter.string(from: NSNumber(value: price)) ?? ""
    }
    
    var formattedDiscountedPrice: String?{
        guard  let dP = discountedPrice else { return nil}
        return currencyFormatter.string(from: NSNumber(value: dP))
    }
    
    var formattedReviewCount: String{
        numberFormatter.string(from: NSNumber(value: reviewCount))!
    }
    
    
    //MARK: - Preview Data
    static let ricky = Person(
        givenName: "Ricky",
        age: 25,
        reviews: [.holly, .dani, .sarah, .madi, .shelby],
        reviewCount: 2249,
        averageReview: 4.5,
        isPrimeEligible: true,
        isSubscribeAndSave: false,
        price: 99.99,
        discountedPrice: 59.99,
        images: ["rickyBeach",
                 "rickyCali",
                 "rickyFood",
                 "rickyBlonde",
                 "rickySwing",
                 "rickyFlex"
        ],
        isBestSeller: true,
        loveLanguage: ["words of affirmation🔊",
                       "physical touch💆🏽‍♂️",
                       "honesty & communication💝",
                       "quality time ⏰",
                       "random acts of adventure🧗🏾"
        ])
    
    static let richard = Person(
        givenName: "Richard",
        age: 25,
        reviews: [.holly, .dani, .sarah, .madi, .shelby],
        reviewCount: 3389,
        averageReview: 3,
        isPrimeEligible: false,
        isSubscribeAndSave: false,
        price: 129.99,
        discountedPrice: 99.99,
        images: [ "rickyCali",
            "rickyBeach",
                 "rickyFood",
                 "rickyBlonde",
                 "rickySwing"
        ],
        isBestSeller: false,
        loveLanguage: ["words of affirmation🔊",
                       "physical touch💆🏽‍♂️",
                       "honesty & communication💝",
                       "quality time ⏰",
                       "random acts of adventure🧗🏾"
        ])
    
    static let rick = Person(
        givenName: "Rick",
        age: 25,
        reviews: [.holly, .dani, .sarah, .madi, .shelby],
        reviewCount: 12277,
        averageReview: 4.5,
        isPrimeEligible: false,
        isSubscribeAndSave: true,
        price: 79.99,
        discountedPrice: 49.99,
        images: [ "rickyFood",
            "rickyBeach",
                 "rickyFood",
                 "rickyBlonde",
                 "rickySwing"
        ],
        isBestSeller: true,
        loveLanguage: ["words of affirmation🔊",
                       "physical touch💆🏽‍♂️",
                       "honesty & communication💝",
                       "quality time ⏰",
                       "random acts of adventure🧗🏾"
        ])
    
    static let rich = Person(
        givenName: "Rich",
        age: 25,
        reviews: [.holly, .dani, .sarah, .madi, .shelby],
        reviewCount: 8163,
        averageReview: 4.5,
        isPrimeEligible: true,
        isSubscribeAndSave: false,
        price: 89.99,
        discountedPrice: 39.99,
        images: [ "rickyBlonde",
                  "rickyBeach",
                 "rickyFood",
                 "rickyBlonde",
                 "rickySwing"
        ],
        isBestSeller: true,
        loveLanguage: ["words of affirmation🔊",
                       "physical touch💆🏽‍♂️",
                       "honesty & communication💝",
                       "quality time ⏰",
                       "random acts of adventure🧗🏾"
        ])
    
    
    static let people = [Person.ricky, .richard, .rick, .rich]
}

struct Review: Identifiable, Equatable{
    let stars: Int
    let title: String
    let comment: String
    let name: String
    let id = UUID()
    
    static let dani = Review(stars: 5,
                                   title: "Would buy again",
                                   comment: "Pretty funny and enjoys doing things outdoors. Really good cook and would give out free massages. Would recommend.",
                                   name: "Danielle Williams")
    
    static let sarah = Review(stars: 5,
                                   title: "Good gym partner",
                                   comment: "Always up for being a good workout buddy. Likes to do things afterwards.",
                                   name: "Sarah Johnson")
    
    static let holly = Review(stars: 5,
                                   title: "Cool plus one",
                                   comment: "Took him as a plus one to my cousins wedding. Had a great time and did a bunch of dancing. Did surprisingly well with meeting the family. Chewed with his mouth closed. Will be taking him to my sisters wedding in the fall.",
                                   name: "Holly Smith")
    
    static let shelby = Review(stars: 5,
                                   title: "Amazing listener",
                                   comment: "I have a lot of problems and Ricky will listen to them all. If I get really upset he'll even buy me ice cream. Fair to say I started getting upset on purpose.",
                                   name: "Shelby Iava")
    
    static let madi = Review(stars: 4,
                                   title: "Snowboarder",
                                   comment: "When he asked to go to the mountain he didn't mention that he was a snowboarder. I don't like waiting for them to strap in every time. Other than that it was a really good time. Cool conversations on the lift and hes up for doing all the black diamonds.",
                                   name: "Madi Tamlin")
}
