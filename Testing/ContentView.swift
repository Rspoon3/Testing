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
    
    var body : some View{
        Text(displayLink.value).onAppear{
            self.displayLink.run(startValue: 0, endValue: 2000000, duration: 5)
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
