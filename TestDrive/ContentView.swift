//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var targetWeight: String = ""
    @State private var mostRecentSample: WeightSample?
    @State private var lastSample: WeightSample?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter target weight (lbs)", text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button {
                    dismissKeyboard()
                    fetchWeightSamples()
                } label: {
                    Text("Fetch Weight Data")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading || targetWeight.isEmpty)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    if let recent = mostRecentSample {
                        Text("🏋️ Most Recent Weight:")
                            .font(.headline)
                        Text("Weight: \(String(format: "%.2f", recent.weight)) lbs")
                        Text("Date: \(recent.date.formatted(date: .long, time: .shortened))")
                    }
                    
                    if let sample = lastSample {
                        Text("🎯 Last Weight at or Below Target:")
                            .font(.headline)
                        Text("Weight: \(String(format: "%.2f", sample.weight)) lbs")
                        Text("Date: \(sample.date.formatted(date: .long, time: .shortened))")
                        
                        Text("⏳ Time Since Then:")
                            .font(.headline)
                        Text(timeDifference(from: sample.date))
                            .font(.body)
                    }
                    
                    if errorMessage != nil && mostRecentSample == nil && lastSample == nil {
                        Text(errorMessage ?? "Unknown error")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Weight History")
            .padding()
            .task {
                await fetchMostRecentWeight()
            }
            .onTapGesture {
                dismissKeyboard()
                fetchWeightSamples()
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
    
    private func fetchWeightSamples() {
        guard let weight = Double(targetWeight) else {
            errorMessage = "Please enter a valid number."
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            lastSample = nil
            
            do {
                lastSample = try await HealthKitManager.shared.fetchLastDateForWeight(atOrBelow: weight)
                
                if lastSample == nil {
                    errorMessage = "No weight data available."
                }
            } catch {
                errorMessage = "Failed to fetch data: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func fetchMostRecentWeight() async {
        do {
            try await HealthKitManager.shared.requestAuthorization()
            mostRecentSample = try await HealthKitManager.shared.fetchMostRecentWeight()
        } catch {
            errorMessage = "Failed to fetch most recent weight: \(error.localizedDescription)"
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func timeDifference(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: date, to: now)
        
        var differenceString = ""
        if let years = components.year, years > 0 {
            differenceString += "\(years) year\(years > 1 ? "s" : "") "
        }
        if let months = components.month, months > 0 {
            differenceString += "\(months) month\(months > 1 ? "s" : "") "
        }
        if let weeks = components.weekOfYear, weeks > 0 {
            differenceString += "\(weeks) week\(weeks > 1 ? "s" : "") "
        }
        if let days = components.day, days > 0 {
            differenceString += "\(days) day\(days > 1 ? "s" : "")"
        }
        
        return differenceString.isEmpty ? "Today" : differenceString
    }
}

#Preview {
    ContentView()
}
