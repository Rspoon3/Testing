//
//  ReactionButtonAnimationManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/1/24.
//

import UIKit
import Combine

final class ReactionButtonAnimationManager {
    static var shared = ReactionButtonAnimationManager()
    private var timer: Timer?
    private var timeUntilFire: TimeInterval?
    let disableShimmer = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        configureTimer()
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseTimer()
            }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.resumeTimer()
            }.store(in: &cancellables)
    }
    
    private func configureTimer() {
//        guard shimmerIsEnabled else { return }

        timer = Timer.scheduledTimer(
            withTimeInterval: 14,
            repeats: false
        ) { [weak self] _ in
            self?.disableCanShowShimmer()
        }
    }
        
    private func disableCanShowShimmer() {
        print("RSW DISABLED")
        timer?.invalidate()
        timer = nil
        disableShimmer.send()
    }
    
    
    func pauseTimer() {
        timeUntilFire = timer?.fireDate.timeIntervalSinceNow
        timer?.invalidate()
        print("pause")
    }

    func resumeTimer() {
        guard
            timer != nil,
            let resumeTime = timeUntilFire
        else {
            return
        }
        
        print("resume ", resumeTime)

        timer = Timer.scheduledTimer(
            withTimeInterval: resumeTime,
            repeats: false
        ) { [weak self] _ in
            self?.disableCanShowShimmer()
        }
    }
}
