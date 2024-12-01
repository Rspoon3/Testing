//
//  CoolNewTripForm.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import SwiftUI

struct CoolNewTripForm: View {
    @ObservedObject var viewModel: TripsViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case name, description
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                // Dynamic Preview
                TripCardPreview(
                    name: viewModel.newTripName,
                    description: viewModel.newTripDescription,
                    icon: viewModel.newTripIcon
                )
                .padding(.bottom, 20)

                // Input Fields
                VStack(spacing: 20) {
                    CoolTextField(
                        title: "Trip Name",
                        text: $viewModel.newTripName,
                        focusedField: $focusedField,
                        field: .name
                    )

                    CoolTextField(
                        title: "Description",
                        text: $viewModel.newTripDescription,
                        focusedField: $focusedField,
                        field: .description
                    )

                    // Emoji Picker
                    CoolEmojiPicker(selectedEmoji: $viewModel.newTripIcon)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Save Button
                Button(action: {
                    viewModel.addTrip()
                    viewModel.showNewTripForm = false
                }) {
                    Text("Save Trip")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(viewModel.newTripName.isEmpty)
                .opacity(viewModel.newTripName.isEmpty ? 0.5 : 1.0)
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showNewTripForm = false
                    }
                }
            }
        }
    }
}
struct CoolTextField: View {
    let title: String
    @Binding var text: String
    @FocusState.Binding var focusedField: CoolNewTripForm.Field?
    let field: CoolNewTripForm.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(focusedField == field ? .blue : .gray)

            TextField("", text: $text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focusedField == field ? Color.blue : Color.gray, lineWidth: 1)
                )
                .focused($focusedField, equals: field)
                .animation(.easeInOut, value: focusedField == field)
        }
        .animation(.easeInOut, value: text)
    }
}
struct CoolEmojiPicker: View {
    @Binding var selectedEmoji: String
    private let emojis = ["🌍", "✈️", "🚗", "🚂", "⛵️", "🏝️", "🗺️"]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pick an Icon")
                .font(.subheadline)
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.largeTitle)
                            .padding()
                            .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                withAnimation {
                                    selectedEmoji = emoji
                                }
                            }
                    }
                }
            }
        }
    }
}
struct TripCardPreview: View {
    var name: String
    var description: String
    var icon: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.largeTitle)
                .padding()
            VStack(alignment: .leading) {
                Text(name.isEmpty ? "Your Trip Name" : name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description.isEmpty ? "Trip Description" : description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}
