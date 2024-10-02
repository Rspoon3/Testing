//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let value = "12345678901234"
    let number1 = PhoneNumber(areaCode: "123", exchange: "456", number: "7890")
    let number2 = PhoneNumber("12345678901234")
    let number3 = PhoneNumber(areaCode: 123, exchange: 456, number: 7890)
    let number4 = PhoneNumber(12345678901234)
    let number5 = PhoneNumber()
    @State private var number6 = PhoneNumber()

    var body: some View {
//        Form {
//            ForEach(1..<value.count, id: \.self) { i in
                let string = String(value.prefix(10))
                
                VStack(alignment: .leading) {
                    Text(number6.formatted(.areaCode))
                    Text(number6.formatted(.excludingAreaCode))
                    Text(number6.formatted(.full))
                    Text(number6.formatted())
                    TextField("Phone Number", value: $number6, format: .phoneNumber)
                    TextField("Phone Number", value: $number6, format: .full)
                }
                
//                VStack(alignment: .leading) {
//                    Text(string)
//                    Text(applyUSAFormat(to: string))
////                    Text(string.formatted(.phoneNumber))
//                    Text(189.formatted(.percent))
//                    Text(Date.now.formatted(.dateTime))
//                    Text(number4.formatted() ?? "No format")
//                    Text(number4.formatted(.areaCode()))
//                    Text(number5.formatted() ?? "No format")
////                    Text(number5.formatted(.full()))
//                    TextField("Phone Number", value: $number6, formatter: .phoneNumber)
//                }
//            }
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
