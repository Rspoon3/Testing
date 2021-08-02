//
//  StepsListView.swift
//  StepsListView
//
//  Created by Richard Witherspoon on 8/1/21.
//

import SwiftUI

struct StepsListView: View{
    @ObservedObject var manager: HealthKitManager

    var body: some View{
        List{
            Section(header: Text("Todays Steps")) {
                Text(manager.todaysSteps.formatted())
            }
            
            Section(header: Text("Total Steps Ever")) {
                Text(manager.totalStepsEver.formatted())
            }
            
            Section(header: Text("Total Steps Each Day This Week (\(manager.totalStepsEachDayThisWeek.sum().formatted()))")) {
                ForEach(manager.totalStepsEachDayThisWeek){ step in
                    Text(step.value.formatted())
                        .badge(Text(step.date.formatted(.dateTime.month(.defaultDigits).day())))
                }
                .onDelete { offsets in
                    manager.totalStepsEachDayThisWeek.remove(atOffsets: offsets)
                }
            }
            
            Section(header: Text("Steps Last Week")) {
                DisclosureGroup(manager.individualStepsLastWeek.sum().formatted()){
                    ForEach(manager.individualStepsLastWeek){ step in
                        Text(step.value.formatted())
                            .badge(Text(step.date.formatted(date: .abbreviated, time: .shortened)))
                    }
                    .onDelete { offsets in
                        manager.individualStepsLastWeek.remove(atOffsets: offsets)
                    }
                }
            }
        }
    }
}



struct StepsListView_Previews: PreviewProvider {
    static var previews: some View {
        StepsListView(manager: HealthKitManager())
    }
}
