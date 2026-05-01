//
//  PurpleSheetView.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import SwiftUI

struct PurpleSheetView: View {
    @StateObject private var purpleSheetModel = PurpleSheetModel()
    @EnvironmentObject private var deepLinkQueue: DeepLinkQueue
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Purple Sheet Listener")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Purple Sheet Status
                VStack(spacing: 16) {
                    Text("Purple Sheet Actions")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total Count:")
                            Spacer()
                            Text("\(purpleSheetModel.purpleSheetCount)")
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        
                        if let lastTime = purpleSheetModel.lastProcessedTime {
                            HStack {
                                Text("Last Processed:")
                                Spacer()
                                Text(lastTime.formatted(.dateTime.hour().minute().second()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !purpleSheetModel.lastPurpleSheetAction.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Action:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(purpleSheetModel.lastPurpleSheetAction)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Test Button
                VStack(spacing: 16) {
                    Text("Test Purple Sheet:")
                        .font(.headline)
                    
                    Button("Trigger Purple Sheet") {
                        if let url = URL(string: "testdrive://color/purple?sheet=true") {
                            deepLinkQueue.enqueue(url: url)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
                
                // Status Info
                Text("This tab listens specifically for purple sheet actions via immediatePublisher")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationTitle("Purple Sheets")
            .sheet(isPresented: $purpleSheetModel.isPurpleSheetPresented) {
                ColorSheet(colorName: "purple")
            }
            .task {
                try? await Task.sleep(for: .seconds(1))
                purpleSheetModel.setupSubscription()
            }
        }
    }
}

#Preview {
    PurpleSheetView()
        .environmentObject(DeepLinkQueue.shared)
}
