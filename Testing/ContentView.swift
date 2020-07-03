//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State var text = String()
    
    var body : some View{
        VStack{
            TextEditor(text: $text)
                .border(Color.blue)
            ScribbleInteraction(text: $text)
                .frame(width: 400, height: 500)
                .border(Color.blue)
        }.padding(.all, 100)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct ScribbleInteraction: UIViewRepresentable {
    let view = UIView()
    let textView = UITextView()

    @Binding var text: String

    func makeUIView(context: Context) -> UIView {
        let scribble = UIIndirectScribbleInteraction(delegate: context.coordinator)
        view.addInteraction(scribble)
        textView.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ mapView: UIView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIIndirectScribbleInteractionDelegate, UITextViewDelegate {
        var parent: ScribbleInteraction

        init(_ parent: ScribbleInteraction) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if let text = textView.text{
                let t = text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: " ").lowercased()
                parent.text = t
            }
        }
        
        // MARK: - UIIndirectScribbleInteractionDelegate
        
        func indirectScribbleInteraction(_ interaction: UIInteraction, shouldDelayFocusForElement elementIdentifier: UUID) -> Bool{
            return false
        }
        
        func indirectScribbleInteraction(_ interaction: UIInteraction, requestElementsIn rect: CGRect,
                                         completion: @escaping ([ElementIdentifier]) -> Void) {
            completion([UUID()])
        }
        
        func indirectScribbleInteraction(_ interaction: UIInteraction, isElementFocused elementIdentifier: UUID) -> Bool {
            return true
        }
        
        
        func indirectScribbleInteraction(_ interaction: UIInteraction, frameForElement elementIdentifier: UUID) -> CGRect {
            return parent.view.frame
        }
            
        func indirectScribbleInteraction(_ interaction: UIInteraction, focusElementIfNeeded elementIdentifier: UUID,
                                         referencePoint focusReferencePoint: CGPoint, completion: @escaping ((UIResponder & UITextInput)?) -> Void) {
            completion(parent.textView)
        }
        
    }
}
