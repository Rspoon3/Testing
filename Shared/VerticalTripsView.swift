//
//  VerticalTripsView.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct VerticalTripsView: View {
    @StateObject private var viewModel = TripsViewModel()
    @State private var expandedTrip: UUID? = nil

    var body: some View {
        ZStack {
            // Animated Background
            WaveBackground()

            VStack {
                // Header
                VStack {
                    Text("Your Trips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    if !viewModel.trips.isEmpty {
                        Text("Tap a trip to view details!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                if viewModel.trips.isEmpty {
                    // Empty State
                    CoolEmptyPlaceholderView {
                        withAnimation {
                            viewModel.showNewTripForm.toggle()
                        }
                    }
                } else {
                    // Trip Cards
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.trips) { trip in
                                TripCardView(
                                    trip: trip,
                                    isExpanded: expandedTrip == trip.id,
                                    onExpand: { expandedTrip = trip.id },
                                    onCollapse: { expandedTrip = nil }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            viewModel.showNewTripForm.toggle()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewTripForm) {
                SleekNewTripForm(viewModel: viewModel)
            }
        }
    }
}
struct WaveBackground: View {
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5) { i in
                    WaveShape()
                        .fill(Color.blue.opacity(Double(0.3 - 0.05 * Double(i))))
                        .frame(height: 150)
                        .offset(y: CGFloat(i * 50))
                        .offset(x: waveOffset)
                        .animation(
                            Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                            value: waveOffset
                        )
                }
            }
            .onAppear {
                waveOffset = geometry.size.width * 0.5
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
struct TripCardView: View {
    let trip: Trip
    let isExpanded: Bool
    let onExpand: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(trip.icon)
                    .font(.largeTitle)
                    .padding()

                VStack(alignment: .leading) {
                    Text(trip.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    if isExpanded {
                        Text(trip.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 4)
                    }
                }

                Spacer()

                Button(action: isExpanded ? onCollapse : onExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }

            if isExpanded {
                // Progress Bar and Actions
                HStack(spacing: 16) {
                    // Progress Bar
                    ProgressView(
                        value: Double(trip.trackedPlates.count) / 50.0,
                        total: 1.0
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 150)

                    // Quick Actions
                    Button {
                        print("Edit Trip")
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }

                    Button {
                        print("Delete Trip")
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
        .shadow(radius: 5)
        .animation(.easeInOut, value: isExpanded)
    }
}
