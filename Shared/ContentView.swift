//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    let title = "All fields below are required to process your receipt. You can view your receipt by tapping the icon in the upper right."
    let addItemsText = "Now please enter all participating items that are on your receipt."
    let navigationTitle = "Correct Receipt"
    @Published var storeTitle = ""
    let storeTitlePlaceholder = "Store Name"
    private let missingText = "MISSING (NULL)"
    let redColor = Color.red
    let grayColor = Color.gray
    @Published var checkoutDate: Date?
    @Published var checkoutTime: Date?
    @Published var suggestions: [String]? = [
        "Walmart", "Target"
    ]
    
    struct Info {
        let inputTitle: String
        let inputTitleColor: Color
        let underlineColor: Color
    }
    
    var canSubmit: Bool {
        !storeTitle.isEmpty &&
        checkoutDate != nil &&
        checkoutTime != nil
    }
    
    var storeInfo: Info {
        let isEmpty = storeTitle.isEmpty
        
        return Info(
            inputTitle:  isEmpty ? missingText : "Store Name",
            inputTitleColor:  isEmpty ? redColor : Color.black,
            underlineColor: isEmpty ? redColor : grayColor
        )
    }
    
    var checkoutDateInfo: Info {
        let missingDate = checkoutDate == nil
        
        return Info(
            inputTitle:  missingDate ? missingText : "Store Name",
            inputTitleColor:  missingDate ? redColor : Color.black,
            underlineColor: missingDate ? redColor : grayColor
        )
    }
    
    var checkoutTimeInfo: Info {
        let missingTime = checkoutTime == nil
        
        return Info(
            inputTitle:  missingTime ? missingText : "Store Name",
            inputTitleColor:  missingTime ? redColor : Color.black,
            underlineColor: missingTime ? redColor : grayColor
        )
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @FocusState var isFocused
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.title)
                       
                    VStack(alignment: .leading, spacing: 20) {
                        storeInput
                        
                        HStack {
                            checkoutDate
                            checkoutTime
                        }
                        
                        receiptTotal
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.addItemsText)
                        
                        Button {
                            
                        } label: {
                            Text("Add Items")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .border(Color.gray)
                        }
                    }
                    .padding(.top, 20)
                    
                    ForEach(0..<10, id: \.self) { _ in
                        Color.red
                            .frame(height: 100)
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { }
                }
                
                    ToolbarItem(placement: .keyboard) {
                        if isFocused, let suggestions = viewModel.suggestions, !suggestions.isEmpty {
//                        HStack {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(suggestion) { }
//                                    .frame(maxWidth: .infinity)
                                    .background(Color(.random()))
//                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Button {
                    
                } label: {
                    Text("Submit Receipt Details")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.canSubmit ? Color.orange : Color.gray)
                        .padding(.horizontal)
                }
                .padding(.bottom)
                .disabled(!viewModel.canSubmit)
            }
            .ignoresSafeArea(.keyboard)

        }
    }
    
    private var storeInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.storeInfo.inputTitle)
                .foregroundStyle(viewModel.storeInfo.inputTitleColor)
            TextField(
                viewModel.storeTitlePlaceholder,
                text: $viewModel.storeTitle
            )
            .focused($isFocused)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.storeInfo.underlineColor)
        }
    }
    
    private var checkoutDate: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.checkoutDateInfo.inputTitle)
                .foregroundStyle(viewModel.checkoutDateInfo.inputTitleColor)
            
            DatePickerTextField(
                placeholderText: "Checkout Date",
                buttonTitle: "Next",
                datePickerMode: .date,
                date: $viewModel.checkoutDate
            ) {
                
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.checkoutDateInfo.underlineColor)
        }
    }
    
    private var checkoutTime: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.checkoutTimeInfo.inputTitle)
                .foregroundStyle(viewModel.checkoutTimeInfo.inputTitleColor)
            
            DatePickerTextField(
                placeholderText: "Checkout Time",
                buttonTitle: "Next",
                datePickerMode: .time,
                date: $viewModel.checkoutDate
            ) {
                
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.checkoutTimeInfo.underlineColor)
        }
    }
    
    private var receiptTotal: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Receipt Total")
//                .foregroundStyle(viewModel.storeInputTitleColor)
            
            DatePickerTextField(
                placeholderText: "",
                buttonTitle: "Next",
                datePickerMode: .time,
                date: $viewModel.checkoutDate
            ) {
                
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.grayColor)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DatePickerTextField : UIViewRepresentable {
    let datePicker = UIDatePicker()
    let textField = UITextField()
    let placeholderText: String
    let buttonTitle: String
    let buttonAction: ()->Void
    let datePickerMode: UIDatePicker.Mode
    @Binding var date: Date?
    
    init(
        placeholderText: String,
        buttonTitle: String,
        datePickerMode: UIDatePicker.Mode,
        date: Binding<Date?>,
        _ buttonAction: @escaping () -> Void
    ) {
        self.placeholderText = placeholderText
        self.buttonTitle = buttonTitle
        self.datePickerMode = datePickerMode
        self.buttonAction = buttonAction
        _date = date
    }
    
    func makeUIView(context: Context) -> some UIView {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let next = UIBarButtonItem(title: buttonTitle, primaryAction: .init(handler: { _ in
            buttonAction()
        }))
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.items = [spacer, next]
        
        datePicker.datePickerMode = datePickerMode
        datePicker.preferredDatePickerStyle = .wheels

        textField.placeholder = placeholderText
        textField.inputView = datePicker
        textField.inputAccessoryView = toolbar
        textField.tintColor = .clear
        
        return textField
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> DatePickerTextField.Coordinator {
         Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: DatePickerTextField
        
        init(_ parent: DatePickerTextField) {
            self.parent = parent
            super.init()
            
            parent.textField.delegate = self
            parent.datePicker.addTarget(
                self,
                action: #selector(
                    setTextFieldToDatePickersDate
                ),
                for: .valueChanged
            )
        }
        
        @objc func setTextFieldToDatePickersDate () {
            if parent.datePickerMode == .date {
                parent.textField.text = parent.datePicker.date.formatted(
                    date: .numeric,
                    time: .omitted
                )
            } else {
                parent.textField.text = parent.datePicker.date.formatted(
                    date: .omitted,
                    time: .shortened
                )
            }
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.datePicker.date = .now
            setTextFieldToDatePickersDate()
        }
    }
}

extension UIColor {
    static func random(alpha: CGFloat = 1.0) -> UIColor {
        let r = CGFloat.random(in: 0...1)
        let g = CGFloat.random(in: 0...1)
        let b = CGFloat.random(in: 0...1)
        
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
    
    static var lightRandom: UIColor {
        random(alpha: 0.3)
    }
}

