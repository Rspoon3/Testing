//
//  PlatesView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import RSWTools

struct PlatesView: View {
    @Namespace private var animation
    let viewModel = PlatesViewViewModel()
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredStates) { state in
                        NavigationLink {
                            PlatesDetailsView(state: state)
                                .backDeployedZoomNavigationTransition(
                                    sourceID: state.id,
                                    in: animation
                                )
                        } label: {
                            VStack {
                                Image("texasPlate")
                                    .resizable()
                                    .scaledToFit()
                                
                                Text(state.title)
                                    .font(.headline)
                                Text(state.tagline)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color(.lightText))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .backDeployedMatchedTransitionSource(
                                id: state.id,
                                in: animation
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Plate-O")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText)
            .animation(.default, value: viewModel.searchText)
            .animation(.default, value: viewModel.sortType)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortType) {
                            ForEach(SortType.allCases) { type in
                                Text(type.rawValue)
                                    .tag(type)
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

enum SortType: String, CaseIterable, Identifiable {
    case title = "Title"
    case year = "Year Founded"
    case number = "State Number"
    case collected = "Collected"
    
    var id: Self { self }
    
    var sortComparator: [SortDescriptor<USState>] {
        switch self {
        case .title:
            [SortDescriptor(\USState.title, order: .forward)]
        case .year:
            [
                SortDescriptor(\USState.yearFounded, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        case .number:
            [
                SortDescriptor(\USState.stateNumber, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        case .collected:
            [
                SortDescriptor(\USState.funDescription, order: .forward),
                SortDescriptor(\USState.title, order: .forward)
            ]
        }
    }
}





@Observable
@MainActor
final class PlatesViewViewModel {
    var sortType: SortType = .title {
        didSet {
            filterAndSortStates()
        }
    }
    var searchText: String = "" {
        didSet {
            filterAndSortStates()
        }
    }
    private var states: [USState] = []
    private(set)var filteredStates: [USState] = []
    
    func filterAndSortStates() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filteredStates = states.sorted(using: sortType.sortComparator)
            return
        }
        
        let filtered = states.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        filteredStates = filtered.sorted(using: sortType.sortComparator)
    }
    
    func loadStates() {
        states = Bundle.main.decode(
            [USState].self,
            from: "states.json"
        )
        
        filterAndSortStates()
    }
}
