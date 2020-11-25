//
//  MockDataManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/24/20.
//

import Foundation


struct MockDataManager{
    let start1 = Calendar.current.date(byAdding: .day, value: -100, to: Date().startOfDay)!
    let end1   = Calendar.current.date(byAdding: .day, value: -70, to: Date().endOfDay)!

    let start2 = Calendar.current.date(byAdding: .day, value: -10, to: Date().startOfDay)!
    let end2   = Calendar.current.date(byAdding: .day, value: -7, to: Date().endOfDay)!

    let start3 = Calendar.current.date(byAdding: .day, value: -5, to: Date().startOfDay)!
    let end3   = Calendar.current.date(byAdding: .day, value: -2, to: Date().endOfDay)!

    let start4 = Date().startOfDay
    let end4   = Calendar.current.date(byAdding: .day, value: 2, to: Date().endOfDay)!

    let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date().startOfDay)!
    
    func fetchDates()->[(Challenge, Date,Date)]{
        let lastPushDate = Calendar.current.date(bySettingHour: 6, minute: 45, second: 8, of: eightDaysAgo)!
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("M/dd h:mm:ss a")

        let challenges = [
            Challenge(title: "Challenge 1", startDate: start1, endDate: end1),
            Challenge(title: "Challenge 2", startDate: start2, endDate: end2),
            Challenge(title: "Challenge 3", startDate: start3, endDate: end3),
            Challenge(title: "Challenge 4", startDate: start4, endDate: end4)
        ]
        
        print("Last Push Date: \(formatter.string(from: lastPushDate))")
        
        print("\nAll challenges")
        for challenge in challenges{
            print(challenge.formattedDates)
        }
        
        
        print("\nChallenges needed to use for last push date")
        for challenge in challenges.filter({$0.endDate >= lastPushDate}){
            print(challenge.formattedDates)
        }
        
        print("\nDate ranges that need to be uploaded")
        var tuples: [(Challenge,Date,Date)] = []
        for challenge in challenges.filter({$0.endDate >= lastPushDate}){
            if lastPushDate > challenge.startDate{
                tuples.append((challenge, lastPushDate, challenge.endDate))
            } else{
                if challenge.endDate > Date(){
                    tuples.append((challenge, challenge.startDate, Date()))
                } else {
                    tuples.append((challenge, challenge.startDate, challenge.endDate))
                }
            }
        }
        
        for tuple in tuples{
            print("\(formatter.string(from: tuple.1)) -  \(formatter.string(from: tuple.2))")
        }
        return tuples
    }
}
