//
//  File.swift
//  Testing
//
//  Created by Richard Witherspoon on 3/23/24.
//

import Foundation

final class Testview : UIInputView {
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: .init(x: 0, y: 0, width: 0, height: 36), inputViewStyle: .keyboard)
        backgroundColor = .systemBlue
        
        let label = UILabel()
        label.text = "asdf"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SuggestionsTextField : UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let textField = UITextField()
        textField.clearButtonMode = .whileEditing
        textField.delegate = context.coordinator
        
//        let toolbar = UIToolbar()
//        toolbar.sizeToFit()
//
//
//        let next = UIBarButtonItem(title: "buttonTitle", primaryAction: .init(handler: { _ in
////            buttonAction()
//        }))
//        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
//        toolbar.items = [spacer, next]
        
     
        let view = Testview()
//        view.sizeToFit()
        
        textField.autocorrectionType = .no
        textField.inputAccessoryView = view//toolbar
        return textField
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> SuggestionsTextField.Coordinator {
         Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SuggestionsTextField
        
        init(_ parent: SuggestionsTextField) {
            self.parent = parent
            super.init()
        }
    }
}
