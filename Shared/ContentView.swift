//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    let value = "12345678901234"
    @State var value2 = "12345678901234"
    let number1 = PhoneNumber(areaCode: "123", exchange: "456", number: "7890")
    let number2 = PhoneNumber("12345678901234")
    let number3 = PhoneNumber(areaCode: 123, exchange: 456, number: 7890)
    let number4 = PhoneNumber(12345678901234)
    let number5 = PhoneNumber()
    @State private var number6 = PhoneNumber()
    @State var someNumber = 123.0
    
    var forLoop: some View {
        ForEach(1..<value.count, id: \.self) { i in
            let string = String(value.prefix(i))

            VStack(alignment: .leading) {
                Text(string)
                Text(PhoneNumber(string).formatted(.areaCode) ?? "")
                Text(PhoneNumber(string).formatted(.excludingAreaCode) ?? "bad")
                Text(PhoneNumber(string).formatted(.full) ?? "bad")
            }
        }
    }
    
    var body: some View {
        Form {
            textFields
        }
    }
    
    var textFields: some View {
        VStack(alignment: .leading) {
            TextField(
                phoneNumber: $number6,
                prompt: Text("Testing")
            ) {
                Text(number6.formatted() ?? "")
            }
            
            TextField("Placeholder", text: $value2)
                .onChange(of: value2) { oldValue, newValue in
                    if newValue.contains("(") && !newValue.contains(")") {
                        let cleaned = newValue.replacingOccurrences(of: "(", with: "")
                        let dropped = String(cleaned.dropLast())
                        value2 = PhoneNumber(dropped).formatted() ?? ""
                    } else {
                        value2 = PhoneNumber(newValue).formatted() ?? ""
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension TextField where Label == Text {
    init(phoneNumber: Binding<PhoneNumber>, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        let phoneNumberString = Binding<String>(
            get: {
                phoneNumber.wrappedValue.formatted() ?? ""
            },
            set: { newValue in
                phoneNumber.wrappedValue = PhoneNumber(newValue)
            }
        )
        
        // Initialize TextField with the custom label and optional prompt
        self.init(text: phoneNumberString, prompt: prompt, label: label)
    }
}
