//
//  SampleDetails.swift
//  SampleDetails
//
//  Created by Richard Witherspoon on 8/2/21.
//

import SwiftUI
import HealthKit

struct SampleDetails: View {
    @State var sample: HealthSample
    let formatter = LengthFormatter()
    @State private var unit = ""
    
    func format(value: Double) -> String{
        let lengthFormatterUnit = HKUnit.lengthFormatterUnit(from: sample.unit)
        formatter.unitStyle = .long
        
        return formatter.string(fromValue: value, unit: lengthFormatterUnit)
    }
    
    var body: some View {
        Form{
            Section("Today"){
                Text(format(value: sample.data.sum()))
            }
            
            if let goal = sample.goal{
                Section("Gaol"){
                    Text(format(value: goal.doubleValue(for: sample.unit)))
                    HStack{
                        Text("Days hit goal")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(sample.data.map(\.value).filter{$0 > goal.doubleValue(for: sample.unit)}.count.formatted())
                    }
                }
            }
            
            Section("Statistics"){
                HStack(alignment: .top){
                    VStack(alignment: . leading){
                        Text("Highest")
                        Text(sample.data.max(by: { a, b in
                            a.value < b.value
                        })?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(format(value: sample.data.map(\.value).max() ?? 0))
                }
                
                HStack(alignment: .top){
                    VStack(alignment: . leading){
                        Text("Lowest")
                        Text(sample.data.min(by: { a, b in
                            a.value < b.value
                        })?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(format(value: sample.data.map(\.value).min() ?? 0))
                }
                
                HStack(alignment: .top){
                    VStack(alignment: . leading){
                        Text("Range")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(format(value: (sample.data.map(\.value).max() ?? 0) - (sample.data.map(\.value).min() ?? 0)))
                }
            }
            
            Section("Supported Units"){
                Picker(selection: $unit, label: Text("Unit")) {
                    ForEach(sample.supportedUnits, id: \.unitString){ unit in
                        Text(unit.unitString)
                            .tag(unit.unitString)
                    }
                }
                .onChange(of: unit) { unit in
                    sample.unit = sample.supportedUnits.first(where: {$0.unitString == unit})!
                }
                .onAppear{
                    unit = sample.unit.unitString
                }
            }
        }
        .navigationBarTitle(sample.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    sample.isFavorite.toggle()
                } label: {
                    Image(systemName: "star")
                        .symbolVariant(sample.isFavorite ? .fill : .none)
                }
            }
        }
    }
}

struct SampleDetails_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            SampleDetails(sample: .distanceWalkingRunning)
        }
    }
}
