//
//  CoolTripView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct CoolTripView: View {
    let trip: Trip
    @State private var showConfetti = false
    @State private var showStatsDetails = false

    var body: some View {
        ZStack {
            // Dynamic Background
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            .overlay(AnimatedBackground())

            VStack(spacing: 20) {
                // Hero Section
                TripHeroView(trip: trip)
                    .onTapGesture {
                        withAnimation {
                            showStatsDetails.toggle()
                        }
                    }

                if showStatsDetails {
                    TripStatsView(trip: trip)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal)
                }

                // Plates Section
                VStack(alignment: .leading) {
                    Text("Tracked Plates")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(trip.trackedPlates) { plate in
                                PlateCardView(state: plate)
                                    .onTapGesture {
                                        withAnimation {
                                            showConfetti = true
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }

                Spacer()
            }

            // Confetti Effect
            if showConfetti {
                ParticleEffectView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showConfetti = false
                            }
                        }
                    }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TripHeroView: View {
    let trip: Trip

    var body: some View {
        VStack {
            Text(trip.icon)
                .font(.system(size: 80))
                .shadow(radius: 5)

            Text(trip.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                StatBadgeView(title: "Plates", value: "\(trip.trackedPlates.count)")
                StatBadgeView(title: "Days", value: "\(daysLeft())")
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private func daysLeft() -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: trip.endDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

struct StatBadgeView: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}


struct TripStatsView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 20) {
            StatBadgeView(title: "Streak", value: "5 Days")
            StatBadgeView(title: "Visited States", value: "\(trip.trackedPlates.count)")
            StatBadgeView(title: "Goal", value: "50%")
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
    }
}

struct PlateCardView: View {
    let state: USState

    var body: some View {
        VStack {
            Text(state.title)
                .font(.headline)
                .padding(10)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(10)

            Text("🌟")
                .font(.largeTitle)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct AnimatedBackground: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<10) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat(50 + i * 10), height: CGFloat(50 + i * 10))
                    .offset(x: offset, y: CGFloat(i * 40))
                    .animation(
                        Animation.easeInOut(duration: 10)
                            .repeatForever(autoreverses: true),
                        value: offset
                    )
            }
        }
        .onAppear {
            offset = 100
        }
    }
}
