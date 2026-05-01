import Foundation
import AVFoundation
import FoundationModels

@Observable
class TranscriptionEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var text: AttributedString
    var url: URL?
    var isDone: Bool
    var summary: String?
    var category: TranscriptionCategory?
    var keyPoints: [String]?

    init(title: String, text: AttributedString = AttributedString(""), url: URL? = nil, isDone: Bool = false) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.text = text
        self.url = url
        self.isDone = isDone
    }

    enum CodingKeys: CodingKey {
        case id, title, date, text, url, isDone, summary, category, keyPoints
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)

        if let textData = try container.decodeIfPresent(Data.self, forKey: .text) {
            if let nsAttrString = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: textData) {
                text = AttributedString(nsAttrString)
            } else {
                text = AttributedString("")
            }
        } else {
            text = AttributedString("")
        }

        url = try container.decodeIfPresent(URL.self, forKey: .url)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        category = try container.decodeIfPresent(TranscriptionCategory.self, forKey: .category)
        keyPoints = try container.decodeIfPresent([String].self, forKey: .keyPoints)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)

        let nsAttrString = NSAttributedString(text)
        let textData = try NSKeyedArchiver.archivedData(withRootObject: nsAttrString, requiringSecureCoding: true)
        try container.encode(textData, forKey: .text)

        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(isDone, forKey: .isDone)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(keyPoints, forKey: .keyPoints)
    }

    func suggestedTitle(style: TitleStyle = .descriptive) async throws -> String? {
        let textContent = String(text.characters)
        guard !textContent.isEmpty else { return nil }

        return try await AIManager.shared.generateTitle(for: textContent, style: style)
    }

    func generateSummary(length: SummaryLength = .medium) async throws -> String? {
        let textContent = String(text.characters)
        guard !textContent.isEmpty else { return nil }

        let generatedSummary = try await AIManager.shared.generateSummary(for: textContent, length: length)
        self.summary = generatedSummary
        return generatedSummary
    }

    func classifyContent() async throws -> TranscriptionCategory? {
        let textContent = String(text.characters)
        guard !textContent.isEmpty else { return nil }

        let detectedCategory = try await AIManager.shared.classifyContent(for: textContent)
        self.category = detectedCategory
        return detectedCategory
    }

    func extractKeyPoints() async throws -> [String]? {
        let textContent = String(text.characters)
        guard !textContent.isEmpty else { return nil }

        let extractedPoints = try await AIManager.shared.extractKeyPoints(for: textContent)
        self.keyPoints = extractedPoints
        return extractedPoints
    }

    func processWithAI() async throws {
        guard AIManager.shared.isAvailable else { return }

        let textContent = String(text.characters)
        guard !textContent.isEmpty else { return }

        async let titleTask = AIManager.shared.generateTitle(for: textContent)
        async let summaryTask = AIManager.shared.generateSummary(for: textContent)
        async let categoryTask = AIManager.shared.classifyContent(for: textContent)

        do {
            let (newTitle, newSummary, newCategory) = try await (titleTask, summaryTask, categoryTask)

            print("AI Results: Title=\(newTitle ?? "nil"), Summary=\(newSummary?.prefix(50) ?? "nil"), Category=\(newCategory?.rawValue ?? "nil")")

            if let newTitle = newTitle, title == "New Transcription" || title.isEmpty {
                self.title = newTitle
                print("Updated title to: \(newTitle)")
            }
            self.summary = newSummary
            self.category = newCategory

            // Also extract key points in the background
            async let keyPointsTask = AIManager.shared.extractKeyPoints(for: textContent)
            self.keyPoints = try? await keyPointsTask
        } catch {
            print("AI processing failed: \(error)")
        }
    }
}

extension TranscriptionEntry {
    static func blank() -> TranscriptionEntry {
        return .init(title: "New Transcription", text: AttributedString(""))
    }

    var hasAudioFile: Bool {
        guard let url = url else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var audioDuration: TimeInterval? {
        guard hasAudioFile, let url = url else { return nil }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let sampleRate = audioFile.processingFormat.sampleRate
            let length = audioFile.length
            return Double(length) / sampleRate
        } catch {
            return nil
        }
    }

    func deleteAudioFile() {
        guard let url = url, hasAudioFile else { return }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete audio file: \(error)")
        }
    }
}