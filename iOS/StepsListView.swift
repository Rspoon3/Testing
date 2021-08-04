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
            Section(header: Text("Today")) {
                Text(manager.todaysData.formatted())
            }
            
            Section(header: Text("Total Ever")) {
                Text(manager.totalDataEver.formatted())
            }
            
            Section(header: Text("Total Each Day This Week (\(manager.thisWeeksDataGroupedByDay.sum().formatted()))")) {
                ForEach(manager.thisWeeksDataGroupedByDay){ data in
                    Text(data.value.formatted())
                        .badge(Text(data.date.formatted(.dateTime.month(.defaultDigits).day())))
                }
                .onDelete { offsets in
                    manager.thisWeeksDataGroupedByDay.remove(atOffsets: offsets)
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
