import SwiftUI
import Combine

extension View {
    func onDebounceChange<T: Equatable>(
        of value: T,
        debounceFor delay: TimeInterval = 0.5,
        perform action: @escaping (T) -> Void
    ) -> some View {
        self.modifier(DebounceChangeModifier(value: value, delay: delay, action: action))
    }
}

private struct DebounceChangeModifier<T: Equatable>: ViewModifier {
    let value: T
    let delay: TimeInterval
    let action: (T) -> Void
    
    @StateObject private var storage: Storage<T>
    @State private var cancellables = Set<AnyCancellable>()
    
    init(value: T, delay: TimeInterval, action: @escaping (T) -> Void) {
        self.value = value
        self.delay = delay
        self.action = action
        self._storage = StateObject(wrappedValue: Storage(initialValue: value, duration: .seconds(delay)))
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                storage.sendToDebouncer(newValue)
            }
            .onAppear {
                storage.debouncedPublisher
                    .sink { debouncedValue in
                        action(debouncedValue)
                    }
                    .store(in: &cancellables)
            }
    }
}

@MainActor
final class Storage<Value>: ObservableObject {
    @Published var value: Value
    private let duration: Duration
    private let debouncedSubject = PassthroughSubject<Value, Never>()
    
    init(initialValue: Value, duration: Duration) {
        self.value = initialValue
        self.duration = duration
    }
    
    var debouncedPublisher: AnyPublisher<Value, Never> {
        debouncedSubject
            .debounce(for: .seconds(duration.timeInterval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateDebounced(_ newValue: Value) {
        value = newValue
        sendToDebouncer(newValue)
    }
    
    func sendToDebouncer(_ newValue: Value) {
        debouncedSubject.send(newValue)
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
