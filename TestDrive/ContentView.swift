//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine

struct Person {
    let firstName: String
    let lastName: String
}

class ContentVM: ObservableObject {
    let repo = BrandsRepository.shared
}

struct ContentView: View {
    @State private var show = true
    @StateObject private var viewModel = ContentVM()
    
    var body: some View {
        Button("Show") {
            show.toggle()
        }
//        .task {
//            for await _ in await viewModel.repo.$brands.values {
//                //                print("got it")
//            }
//        }
        
        if show {
            ExampleView()
        }
    }
}

@MainActor
class ExampleVM: ObservableObject {
    let repo = BrandsRepository.shared
    @Published var count = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("ExampleVM init")
        Task { [weak self] in
                        guard let test = await self?.repo.$brands else { return }
//            guard let self else { return }

            for await _ in await test {
                guard let self else { return }
                self.count += 1
                print(self.count)
            }
        }
        .store(in: &cancellables)
        
        
        repo.test
            .sink { _ in
                
            } receiveValue: { _ in
                
            }.store(in: &cancellables)

     
        print(repo.test.value)
    }
    
    deinit {
        print("ExampleVM deinit")
    }
}


struct ExampleView: View {
    @StateObject private var viewModel = ExampleVM()
    
    var body: some View {
        Text("Example: \(viewModel.count)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

final actor BrandsRepository {
    static let shared = BrandsRepository()
    private var brands = [Person]() {
        didSet {
            test.send(brands)
        }
    }
    private var subscriptions = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    let test = CurrentValueSubject<[Person], Never>([])
    
    // MARK: - Initializer
    private init () {
        print("BrandsRepository init")
        
        Task {
            await configureNotificationObservers()
        }
        print("Still waitin")
        
    }
    
    deinit {
        print("BrandsRepository deinit")
    }
    
    // MARK: - Public
    
    func update(_ brands: [Person]) {
        self.brands = brands
    }
    
    func removeAllBrands() {
        brands.removeAll()
        
        
        notificationCenter.publisher(for: .init(""))
            .sink { _ in
                
            }.store(in: &subscriptions)
        
    }
    
    // MARK: - Private
    
    private func configureNotificationObservers() async {
        for await _ in await notificationCenter.notifications(named: UIDevice.orientationDidChangeNotification) {
            //            print("Here")
            removeAllBrands()
        }
    }
}
extension Task {
    func store(in cancellables: inout Set<AnyCancellable>) {
        asCancellable().store(in: &cancellables)
    }
    
    func asCancellable() -> AnyCancellable {
        .init { self.cancel() }
    }
}
