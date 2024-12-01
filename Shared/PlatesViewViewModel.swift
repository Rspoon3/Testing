//
//  PlatesViewViewModel.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//

import Foundation

@Observable
@MainActor
final class PlatesViewViewModel {
    var showLocationPrompt = false
    var sortType: SortType {
        didSet {
            UserDefaults.standard.set(sortType.rawValue, forKey: "platesViewViewModel.sortType")
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
    
    
    init() {
        let value = UserDefaults.standard.integer(forKey: "platesViewViewModel.sortType")
        self.sortType = SortType(rawValue: value) ?? .title
    }
    
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
