//
//  HeaderView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct HeaderView: View {
    let collectedCount: Int
    
    private var progress: Double {
        Double(collectedCount) / Double(50)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Your Collection")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                    
                    Text("\(collectedCount)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 10)
         
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plates Collected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Keep collecting to complete your set!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}

struct HeaderViewV2: View {
    let collectedCount: Int
    
    private var progress: Double {
        Double(collectedCount) / Double(50)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Your Collection")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Gauge(value: 25, in: 0...50) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                } currentValueLabel: {
                    Text("4")
                        .foregroundColor(Color.green)
                } minimumValueLabel: {
                    Text("0")
                        .foregroundColor(Color.green)
                } maximumValueLabel: {
                    Text("50")
                        .foregroundColor(Color.red)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.red, .yellow, .green]))
                .padding(.bottom, 10)
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plates Collected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Keep collecting to complete your set!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}

struct HeaderViewV3: View {
    let collectedCount: Int
    let totalCount: Int
    let streak: Int
    
    private var progress: Double {
        Double(collectedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack {
            // Circular badge
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(Color.blue, lineWidth: 5)
                    .frame(width: 100, height: 100)
                VStack {
                    Text("\(collectedCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Collected")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom, 10)
            
            // Progress and streak
            Text("You're \(Int(progress * 100))% complete!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                Text("Current Streak: \(streak) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Divider for a clean look
            Divider()
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}
struct HeaderViewV4: View {
    let collectedCount: Int
    let totalCount: Int
    
    private var progress: Double {
        Double(collectedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Your Collection")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AngularGradient(
                        gradient: Gradient(colors: [.blue, .green]),
                        center: .center
                    ), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                // Collected number
                VStack {
                    Text("\(collectedCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Collected")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom, 10)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}


import SwiftUI

struct HeaderViewV22: View {
    let collectedCount: Int

    private var progress: Double {
        Double(collectedCount) / Double(50)
    }

    private var motivationalMessage: String {
        switch collectedCount {
        case 0:
            return "Let's get started!"
        case 1..<10:
            return "Great start! Keep going!"
        case 10..<30:
            return "You're halfway there!"
        case 30..<50:
            return "So close! Almost done!"
        default:
            return "Congratulations! You've completed your collection!"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Your Collection")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Motivational Message
            Text(motivationalMessage)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Animated Progress Bar and Stats
            HStack(spacing: 20) {
                ZStack {
                    // Circular Progress Indicator
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .yellow, .green]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .opacity(0.3)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .yellow, .green]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                        .animation(.easeOut(duration: 1), value: progress)

                    // Collected Count in the Middle
                    VStack {
                        Text("\(collectedCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("/ 50")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats and Encouragement
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plates Collected")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("You're \(50 - collectedCount) plates away from completion!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Fun Emoji Strip
            HStack {
                ForEach(0..<min(5, collectedCount), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                }
                if collectedCount < 50 {
                    ForEach(0..<(5 - min(5, collectedCount)), id: \.self) { _ in
                        Image(systemName: "star")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}
