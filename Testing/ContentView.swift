//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct Wave: Shape {
    // allow SwiftUI to animate the wave phase
    var animatableData: Double {
        get { phase }
        set { self.phase = newValue }
    }

    // how high our waves should be
    var strength: Double

    // how frequent our waves should be
    var frequency: Double

    // how much to offset our waves horizontally
    var phase: Double

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()

        // calculate some important values up front
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midWidth = width / 2
        let midHeight = height / 2
        let oneOverMidWidth = 1 / midWidth

        // split our total width up based on the frequency
        let wavelength = width / frequency

        // start at the left center
        path.move(to: CGPoint(x: 0, y: midHeight))

        // now count across individual horizontal points one by one
        for x in stride(from: 0, through: width, by: 1) {
            // find our current position relative to the wavelength
            let relativeX = x / wavelength

            // find how far we are from the horizontal center
            let distanceFromMidWidth = x - midWidth

            // bring that into the range of -1 to 1
            let normalDistance = oneOverMidWidth * distanceFromMidWidth

            let parabola = -(normalDistance * normalDistance) + 1

            // calculate the sine of that position, adding our phase offset
            let sine = sin(relativeX + phase)

            // multiply that sine by our strength to determine final offset, then move it down to the middle of our view
            let y = parabola * strength * sine + midHeight

            // add a line to here
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return Path(path.cgPath)
    }
}

struct ContentView: View {
    @State private var phase           = 0.0
    @State private var strength        = 50.0
    @State private var frequency       = 5.0
    @State private var useOffset       = true
    @State private var adjustFrequency = true
    @State private var adjustPhase     = true
    
    var body: some View {
        VStack{
            Group{
                HStack{
                    Text(String(format: "Strength: %.2f", strength))
                    Slider(value: $strength, in: 0.0...100.0)
                }
                HStack{
                    Text(String(format: "Frequency: %.2f", frequency))
                    Slider(value: $frequency, in: 0.0...100.0)
                }
                Toggle("Use Offset", isOn: $useOffset)
                Toggle("Adjust Phase", isOn: $adjustPhase)
                Toggle("Adjust Frequency", isOn: $adjustFrequency)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            ZStack {
                Color.blue.edgesIgnoringSafeArea(.all)
                ForEach(0..<10) { i in
                    Wave(strength: self.strength,
                         frequency: self.adjustFrequency ? self.frequency + Double(i) : self.frequency,
                         phase: self.adjustPhase ?  self.phase + Double(i) : self.phase
                    )
                        .stroke(Color.white.opacity(Double(i) / 10), lineWidth: 5)
                        .offset(y: self.useOffset ? CGFloat(i) * 10 : 0)
                }
            }
        }
        .background(Color.blue.opacity(0.4).edgesIgnoringSafeArea(.all))
        .onAppear {
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                self.phase = .pi * 2
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

