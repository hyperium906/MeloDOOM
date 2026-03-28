//
//  AIWorkspaceService.swift
//  MeloDOOM
//
//  Created by Codex on 3/28/26.
//

import Foundation

struct GeminiService {
    func generateText(prompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            throw AIWorkspaceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [
            GeminiContent(parts: [GeminiPart(text: prompt)])
        ]))

        let (data, response) = try await URLSession.shared.data(for: request)
        try AIWorkspaceError.validate(response: response, data: data)

        let decodedResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard
            let text = decodedResponse.candidates.first?.content.parts
                .compactMap(\.text)
                .joined()
                .trimmingCharacters(in: .whitespacesAndNewlines),
            text.isEmpty == false
        else {
            throw AIWorkspaceError.emptyResponse
        }

        return text
    }
}

struct NotionService {
    private let notionVersion = "2022-06-28"

    func createDatabaseEntry(log: NotionDailyLog, databaseID: String, token: String) async throws {
        guard let url = URL(string: "https://api.notion.com/v1/pages") else {
            throw AIWorkspaceError.invalidRequest
        }

        let blocks = makeParagraphBlocks(from: log.content)
        let requestBody = NotionCreatePageRequest(
            parent: NotionParent(databaseID: databaseID),
            properties: NotionProperties(log: log),
            children: blocks
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try AIWorkspaceError.validate(response: response, data: data)
    }

    private func makeParagraphBlocks(from content: String) -> [NotionBlock] {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let paragraphs = trimmedContent
            .components(separatedBy: "\n\n")
            .flatMap(chunkParagraph)
            .filter { $0.isEmpty == false }

        return paragraphs.map { paragraph in
            NotionBlock(
                object: "block",
                type: "paragraph",
                paragraph: NotionParagraph(
                    richText: [
                        NotionRichText(
                            type: "text",
                            text: NotionText(content: paragraph)
                        )
                    ]
                )
            )
        }
    }

    private func chunkParagraph(_ paragraph: String) -> [String] {
        let cleanedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedParagraph.count > 1800 else {
            return cleanedParagraph.isEmpty ? [] : [cleanedParagraph]
        }

        var chunks: [String] = []
        var currentChunk = ""

        for word in cleanedParagraph.split(separator: " ", omittingEmptySubsequences: true) {
            let candidate = currentChunk.isEmpty ? String(word) : "\(currentChunk) \(word)"

            if candidate.count > 1800 {
                chunks.append(currentChunk)
                currentChunk = String(word)
            } else {
                currentChunk = candidate
            }
        }

        if currentChunk.isEmpty == false {
            chunks.append(currentChunk)
        }

        return chunks
    }
}

struct NotionDailyLog {
    let title: String
    let loggedAt: Date
    let mood: String
    let overallScore: Int
    let financeScore: Int
    let carbonScore: Int
    let digitalScore: Int
    let foodSpend: Double
    let clothesSpend: Double
    let extracurricularSpend: Double
    let carMiles: Double
    let transitMiles: Double
    let streamingHours: Double
    let meatMeals: Int
    let flightsThisMonth: Int
    let screenHours: Double
    let socialHours: Double
    let aiPrompts: Int
    let moodSummary: String
    let geminiSummary: String
    let content: String
}

enum AIWorkspaceError: LocalizedError {
    case emptyResponse
    case invalidRequest
    case invalidResponse(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The API returned no text."
        case .invalidRequest:
            return "The request could not be created."
        case let .invalidResponse(statusCode, message):
            return "Request failed (\(statusCode)): \(message)"
        }
    }

    static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIWorkspaceError.invalidRequest
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIWorkspaceError.invalidResponse(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Encodable, Decodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable, Decodable {
    let text: String?

    init(text: String) {
        self.text = text
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

private struct NotionCreatePageRequest: Encodable {
    let parent: NotionParent
    let properties: NotionProperties
    let children: [NotionBlock]
}

private struct NotionParent: Encodable {
    let type = "database_id"
    let databaseID: String

    enum CodingKeys: String, CodingKey {
        case type
        case databaseID = "database_id"
    }
}

private struct NotionProperties: Encodable {
    let name: NotionTitleProperty
    let date: NotionDateProperty
    let mood: NotionSelectProperty
    let overallScore: NotionNumberProperty
    let financeScore: NotionNumberProperty
    let carbonScore: NotionNumberProperty
    let digitalScore: NotionNumberProperty
    let foodSpend: NotionNumberProperty
    let clothesSpend: NotionNumberProperty
    let extracurricularSpend: NotionNumberProperty
    let carMiles: NotionNumberProperty
    let transitMiles: NotionNumberProperty
    let streamingHours: NotionNumberProperty
    let meatMeals: NotionNumberProperty
    let flightsThisMonth: NotionNumberProperty
    let screenHours: NotionNumberProperty
    let socialHours: NotionNumberProperty
    let aiPrompts: NotionNumberProperty
    let moodSummary: NotionRichTextProperty
    let geminiSummary: NotionRichTextProperty

    init(log: NotionDailyLog) {
        name = NotionTitleProperty(
            title: [
                NotionRichText(
                    type: "text",
                    text: NotionText(content: log.title)
                )
            ]
        )
        date = NotionDateProperty(date: NotionDateValue(start: ISO8601DateFormatter().string(from: log.loggedAt)))
        mood = NotionSelectProperty(select: NotionSelectValue(name: log.mood))
        overallScore = NotionNumberProperty(number: Double(log.overallScore))
        financeScore = NotionNumberProperty(number: Double(log.financeScore))
        carbonScore = NotionNumberProperty(number: Double(log.carbonScore))
        digitalScore = NotionNumberProperty(number: Double(log.digitalScore))
        foodSpend = NotionNumberProperty(number: log.foodSpend)
        clothesSpend = NotionNumberProperty(number: log.clothesSpend)
        extracurricularSpend = NotionNumberProperty(number: log.extracurricularSpend)
        carMiles = NotionNumberProperty(number: log.carMiles)
        transitMiles = NotionNumberProperty(number: log.transitMiles)
        streamingHours = NotionNumberProperty(number: log.streamingHours)
        meatMeals = NotionNumberProperty(number: Double(log.meatMeals))
        flightsThisMonth = NotionNumberProperty(number: Double(log.flightsThisMonth))
        screenHours = NotionNumberProperty(number: log.screenHours)
        socialHours = NotionNumberProperty(number: log.socialHours)
        aiPrompts = NotionNumberProperty(number: Double(log.aiPrompts))
        moodSummary = NotionRichTextProperty(text: log.moodSummary)
        geminiSummary = NotionRichTextProperty(text: log.geminiSummary)
    }

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case date = "Date"
        case mood = "Mood"
        case overallScore = "Overall Score"
        case financeScore = "Finance Score"
        case carbonScore = "Carbon Score"
        case digitalScore = "Digital Score"
        case foodSpend = "Food Spend"
        case clothesSpend = "Clothes Spend"
        case extracurricularSpend = "Extracurricular Spend"
        case carMiles = "Car Miles"
        case transitMiles = "Transit Miles"
        case streamingHours = "Streaming Hours"
        case meatMeals = "Meat Meals"
        case flightsThisMonth = "Flights This Month"
        case screenHours = "Screen Hours"
        case socialHours = "Social Hours"
        case aiPrompts = "AI Prompts"
        case moodSummary = "Mood Summary"
        case geminiSummary = "Gemini Summary"
    }
}

private struct NotionTitleProperty: Encodable {
    let title: [NotionRichText]
}

private struct NotionDateProperty: Encodable {
    let date: NotionDateValue
}

private struct NotionDateValue: Encodable {
    let start: String
}

private struct NotionSelectProperty: Encodable {
    let select: NotionSelectValue
}

private struct NotionSelectValue: Encodable {
    let name: String
}

private struct NotionNumberProperty: Encodable {
    let number: Double
}

private struct NotionRichTextProperty: Encodable {
    let richText: [NotionRichText]

    init(text: String) {
        richText = [
            NotionRichText(
                type: "text",
                text: NotionText(content: text)
            )
        ]
    }

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

private struct NotionBlock: Encodable {
    let object: String
    let type: String
    let paragraph: NotionParagraph
}

private struct NotionParagraph: Encodable {
    let richText: [NotionRichText]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

private struct NotionRichText: Encodable {
    let type: String
    let text: NotionText
}

private struct NotionText: Encodable {
    let content: String
}
