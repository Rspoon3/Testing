//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine

protocol TimerProtocol {
    func getTimerPublisher() -> AnyPublisher<Date, Never>
}

extension Timer.TimerPublisher: TimerProtocol {
    func getTimerPublisher() -> AnyPublisher<Date, Never> {
        return self
            .autoconnect()
            .eraseToAnyPublisher()
    }
}

final class MockTimer: TimerProtocol {
    func getTimerPublisher() -> AnyPublisher<Date, Never> {
        return Just(Date())
            .eraseToAnyPublisher()
    }
}

class ContentViewModel: ObservableObject {
    private(set) var currentID = 0
    private var timerCancellable: Cancellable?
    private var didBecomeActiveCancellable: Cancellable?
    private let timer: TimerProtocol
    private let notificationCenter: NotificationCenter
    let shouldAutoScroll = PassthroughSubject<Void, Never>()
    
    init(timer: TimerProtocol = Timer.publish(every: 6, on: .main, in: .default),
         notificationCenter: NotificationCenter = .default) {
        self.timer = timer
        self.notificationCenter = notificationCenter
        
        configureNCPublisher()
        restartTimer()
    }
    
    private func configureNCPublisher() {
        didBecomeActiveCancellable = notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.restartTimer()
            }
    }
    
    func restartTimer() {
        stopTimer()
        timerCancellable = timer.getTimerPublisher()
            .sink { [weak self] _ in
                print("INCREASING")
                self?.currentID += 1
                self?.shouldAutoScroll.send()
            }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

struct ContentView: View {
    @StateObject var model = ContentViewModel()
    
    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<200){ i in
                            Color(i.isMultiple(of: 2) ? .systemBlue : .systemOrange)
                                .frame(width: 393, height: 393/2)
                                .id(i)
                                .overlay(
                                    Text(i.description)
                                        .foregroundColor(.white)
                                        .font(.largeTitle)
                                )
                        }
                    }
                }
                .onReceive(model.shouldAutoScroll) { _ in
                    withAnimation{
                        reader.scrollTo(model.currentID)
                    }
                }
            }
            
            Button("Simulate Swipe") {
                model.stopTimer()
            }
        }
        .font(.title)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
