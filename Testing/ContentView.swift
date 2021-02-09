//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import DisplayLink

struct ContentView : View {
    @ObservedObject var displayLink = DisplayLinkManager()
    @State private var number = 0
    let duration = 4.0
    let endValue = 100.0
    
    var body : some View{
        VStack{
            Text(displayLink.value)
                .onAppear{
                    self.displayLink.run(startValue: 0, endValue: endValue, duration: duration)
                }
            
            Text(String(number))
                .modifier(NumberView(number: number))
                .onAppear{
                    withAnimation(Animation.linear(duration: duration)) {
                        number = Int(endValue)
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


class DisplayLinkManager: ObservableObject{
    @Published var value = ""
    
    var startValue: Double!
    var endValue:   Double!
    var duration:   Double!
    var asInteger : Bool!
    
    let animationStartDate = Date()
    
    var displayLink: CADisplayLink?
    
    func configureDisplayLink(){
        
    }
    
    func run(startValue : Double, endValue : Double, duration: Double, asInteger : Bool = true){
        self.startValue = startValue
        self.endValue = endValue
        self.duration = duration
        self.asInteger = asInteger
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink.add(to: .main, forMode: .default)
    }
    
    
    @objc func handleUpdate() {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(animationStartDate)
        
        if elapsedTime > duration {
            value = String(format: "%.\(asInteger ? 0 : 3)f", endValue)
            displayLink?.invalidate()
            displayLink = nil
        } else {
            let percentage = elapsedTime / duration
            let newValue = startValue + percentage * (endValue - startValue)
        
            value = String(format: "%.\(asInteger ? 0 : 3)f", newValue)
        }
    }
}


struct NumberView: AnimatableModifier {
    var number: Int

    var animatableData: CGFloat {
        get { CGFloat(number) }
        set { number = Int(newValue) }
    }

    func body(content: Content) -> some View {
        Text(String(number))
    }
}
