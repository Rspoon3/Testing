//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import LoremSwiftum

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            HStack(spacing: 3) {
                Circle()
                    .foregroundStyle(.yellow)
                    .frame(width: 15)
                    .foregroundStyle(.secondary)
                Text(viewModel.totalPoints.formatted())
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .padding(.leading)
            }
            .padding(.vertical)
            .padding(.leading, 30)
            .padding(.trailing, 10)
            .background {
                Color.black.opacity(0.1)
            }
            .cornerRadius(10)
            
            HStack(spacing: 3) {
                Image(systemName: "car.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Ralphs")
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 30)
            .background {
                Capsule()
                    .foregroundStyle(.black.opacity(0.1))
            }
            
            List {
                ForEach(viewModel.items) { item in
                    ListItemRow(item: item)
                }
                
                TextField(text: $viewModel.newItem) {
                    HStack {
                        Text("Add Item")
                        if viewModel.saving {
                            ProgressView()
                        }
                    }
                }
                .onSubmit() {
                    viewModel.submit()
                }
            }
            .listStyle(.plain)
            
            
            HStack(spacing: 10) {
                //                Text(viewModel.suggestedOffer.title)
                
                HStack(spacing: 3) {
                    Circle()
                        .foregroundStyle(.yellow)
                        .frame(width: 15)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalPoints.formatted())
                        .foregroundStyle(.primary)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                Color.black.opacity(0.1)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
