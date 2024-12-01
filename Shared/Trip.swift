//
//  Trip.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct Trip: Identifiable {
    let id = UUID()
    var name: String
    var startDate: Date
    var endDate: Date
    var description: String
    var icon: String // Emoji or SF Symbol
    var trackedPlates: [USState] // Plates tracked during the trip
}

class TripsViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var newTripName = ""
    @Published var newTripDescription = ""
    @Published var newTripIcon = "✈️"
    @Published var showNewTripForm = false

    func addTrip() {
        let trip = Trip(
            name: newTripName,
            startDate: Date(),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 7), // 1 week later
            description: newTripDescription,
            icon: newTripIcon,
            trackedPlates: []
        )
        trips.append(trip)
        resetForm()
    }

    private func resetForm() {
        newTripName = ""
        newTripDescription = ""
        newTripIcon = "✈️"
    }
}

struct TripsView: View {
    @StateObject private var viewModel = TripsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.trips.isEmpty {
                    EmptyPlaceholderView {
                        viewModel.showNewTripForm.toggle()
                    }
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.trips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showNewTripForm.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewTripForm) {
                NewTripForm(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    TripsView()
}

struct TripCard: View {
    let trip: Trip

    var body: some View {
        HStack {
            Text(trip.icon)
                .font(.largeTitle)
                .padding()
            VStack(alignment: .leading) {
                Text(trip.name)
                    .font(.headline)
                Text(trip.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(trip.trackedPlates.count) plates tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}


struct NewTripForm: View {
    @ObservedObject var viewModel: TripsViewModel

    var body: some View {
        NavigationStack {
            Form {
                TextField("Trip Name", text: $viewModel.newTripName)
                TextField("Description", text: $viewModel.newTripDescription)
                Picker("Icon", selection: $viewModel.newTripIcon) {
                    ForEach(["✈️", "🚗", "🚂", "⛵️", "🏝️", "🗺️"], id: \.self) {
                        Text($0)
                    }
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addTrip()
                        viewModel.showNewTripForm = false
                    }
                    .disabled(viewModel.newTripName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showNewTripForm = false
                    }
                }
            }
        }
    }
}


struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        VStack {
            Text("\(trip.icon) \(trip.name)")
                .font(.largeTitle)
                .padding()
            PlatesView() // Reuse your existing PlatesView for plate tracking
        }
        .navigationTitle(trip.name)
    }
}


import SwiftUI

struct EmptyPlaceholderView: View {
    var onAddTrip: () -> Void

    @State private var bounce = false

    var body: some View {
        VStack {
            // Animated Icon
            Text("🌎")
                .font(.system(size: 100))
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: bounce
                )
                .onAppear {
                    bounce = true
                }
                .padding(.bottom, 20)

            // Encouraging Message
            Text("Start your adventure!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Text("Create your first trip and start tracking plates from all over the country. Let’s make it memorable!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)

            // Fun Call-to-Action Button
            Button(action: onAddTrip) {
                Label("Add a New Trip", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding()

            Spacer()

            // Subtle Background Graphics
            HStack {
                Spacer()
                Image(systemName: "airplane")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray.opacity(0.2))
                    .rotationEffect(.degrees(-30))
                    .offset(x: -20, y: 20)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
