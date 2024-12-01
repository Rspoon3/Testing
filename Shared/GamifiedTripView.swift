//
//  GamifiedTripView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct GamifiedTripView: View {
    let trip: Trip
    @State private var selectedState: USState? = nil

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Hero Section
                TripHero(trip: trip)

                // Progress Section
                TripProgressView(progress: CGFloat(trip.trackedPlates.count) / 50.0)

                // Interactive Map
                Text("Visited States")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(trip.trackedPlates) { state in
                            StateBadge(state: state)
                                .onTapGesture {
                                    withAnimation {
                                        selectedState = state
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Journal Section
                TripJournalSection()

                Spacer()
            }

            // State Details Modal
            if let state = selectedState {
                StateDetailsView(state: state) {
                    withAnimation {
                        selectedState = nil
                    }
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct TripHero: View {
    let trip: Trip

    var body: some View {
        VStack {
            Text(trip.icon)
                .font(.system(size: 80))
                .shadow(radius: 10)
                .padding()

            Text(trip.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(trip.trackedPlates.count) plates collected!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct TripProgressView: View {
    let progress: CGFloat

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.white)

                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: 270))
                    .animation(.easeInOut, value: progress)

                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Goal Reached")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 150, height: 150)
        }
    }
}

struct StateBadge: View {
    let state: USState

    var body: some View {
        VStack {
            Text(state.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.blue)
                .cornerRadius(10)

            Text("🎉")
                .font(.largeTitle)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
struct StateDetailsView: View {
    let state: USState
    let onClose: () -> Void

    var body: some View {
        VStack {
            Text(state.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Fun Facts: \(state.neatFact)")
                .font(.body)
                .padding()

            Button(action: onClose) {
                Text("Close")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .frame(maxWidth: 300)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale)
    }
}

struct TripJournalSection: View {
    @State private var journalText = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Trip Journal")
                .font(.headline)
                .foregroundColor(.white)

            TextEditor(text: $journalText)
                .frame(height: 150)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}
