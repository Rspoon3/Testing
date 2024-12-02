//
//  PlatesView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import RSWTools

struct PlatesView: View {
    @AppStorage("header") private var currentHeader = 0
    let viewModel = PlatesViewViewModel()
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ScrollView {
                if viewModel.searchText.isEmpty {
                    if currentHeader == 0 {
                        HeaderView(collectedCount: 3)
                    } else if currentHeader == 1 {
                        HeaderViewV2(collectedCount: 3)
                    } else if currentHeader == 2 {
                        HeaderViewV3(collectedCount: 4, totalCount: 7, streak: 4)
                    } else if currentHeader == 3 {
                        HeaderViewV22(collectedCount: 4)
                    }else {
                        HeaderViewV4(collectedCount: 4, totalCount: 50)
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredStates) { state in
                        PlateCell(state: state)
                    }
                }
                .padding()
            }
            .navigationTitle("Plate-O")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText)
            .animation(.default, value: viewModel.searchText)
            .animation(.default, value: viewModel.sortType)
//            .fullScreenCover(isPresented: $viewModel.showLocationPrompt) {
//                PrivacyScreen()
//            }
            .onAppear {
                viewModel.showLocationPrompt.toggle()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortType) {
                            ForEach(SortType.allCases) { type in
                                Text(type.title)
                                    .tag(type)
                            }
                        }
                        
                        Picker("Header", selection: $currentHeader) {
                            ForEach(0..<5, id: \.self) { i in
                                Button(i.formatted()) {
                                    currentHeader = i
                                }
                            }
                        }
                    } label: {
                        Image(symbol: .ellipsisCircle)
                    }
                }
            }
            .onAppear {
                viewModel.loadStates()
            }
        }
    }
}

#Preview {
    PlatesView()
}
