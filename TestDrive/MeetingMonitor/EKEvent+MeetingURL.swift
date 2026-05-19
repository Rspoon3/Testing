//
//  EKEvent+MeetingURL.swift
//  TestDrive
//

import EventKit
import Foundation

extension EKEvent {

    /// First URL associated with the event, looking at the dedicated `url` field
    /// and then any links embedded in the notes or location.
    var firstMeetingURL: URL? {
        if let url { return url }
        let candidates = [notes, location].compactMap { $0 }
        for text in candidates {
            if let url = Self.firstURL(in: text) {
                return url
            }
        }
        return nil
    }

    private static func firstURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, range: range)?.url
    }
}
