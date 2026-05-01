import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published var value: Int = 0
    @Published var count: Int = 0
    let test = Test()
    
    private var cancellables = Set<AnyCancellable>()
    
    let store: IntegerStore
    
    init(
        store: IntegerStore = IntegerStore(),
    ) {
        self.store = store
        
        // Observe IntStore
        store.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.value = newValue
            }
            .store(in: &cancellables)
    }
    
    func incrementIntStore() {
        store.increment()
    }
    
    func decrementIntStore() {
        store.decrement()
    }
    
    func watchTest() async {
        await test.$value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.count = newValue
            }
            .store(in: &cancellables)
    }
}
