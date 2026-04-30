import Foundation
import Vision
import UIKit

struct ParsedStats: Equatable {
    var followers: Int?
    var following: Int?
    var posts: Int?
    var likes: Int?

    var hasAnything: Bool {
        followers != nil || following != nil || posts != nil || likes != nil
    }
}

enum OCRService {

    static func parse(image: UIImage) async -> ParsedStats {
        let items = (try? await recognizeText(in: image)) ?? []
        return parseStats(from: items)
    }

    // MARK: - Vision

    private struct TextItem {
        let text: String
        let bbox: CGRect   // normalized, origin bottom-left
    }

    private static func recognizeText(in image: UIImage) async throws -> [TextItem] {
        guard let cgImage = image.cgImage else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, err in
                if let err {
                    continuation.resume(throwing: err)
                    return
                }
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                let items = observations.compactMap { obs -> TextItem? in
                    guard let candidate = obs.topCandidates(1).first?.string else { return nil }
                    return TextItem(text: candidate, bbox: obs.boundingBox)
                }
                continuation.resume(returning: items)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Parsing

    private static func parseStats(from items: [TextItem]) -> ParsedStats {
        var result = ParsedStats()

        let labelMap: [(needle: String, assign: (inout ParsedStats, Int) -> Void)] = [
            ("followers", { $0.followers = $1 }),
            ("following", { $0.following = $1 }),
            ("posts",     { $0.posts = $1 }),
            ("likes",     { $0.likes = $1 }),
        ]

        for item in items {
            let lower = item.text.lowercased()
            for entry in labelMap {
                if lower.contains(entry.needle) {
                    if let n = nearestNumber(to: item, in: items) {
                        entry.assign(&result, n)
                    }
                }
            }
        }
        return result
    }

    private static func nearestNumber(to label: TextItem, in items: [TextItem]) -> Int? {
        let labelCenter = CGPoint(x: label.bbox.midX, y: label.bbox.midY)
        var best: (Int, CGFloat)?
        for item in items {
            guard let n = parseNumber(item.text) else { continue }
            let c = CGPoint(x: item.bbox.midX, y: item.bbox.midY)
            let dx = c.x - labelCenter.x
            let dy = c.y - labelCenter.y
            let dist = sqrt(dx * dx + dy * dy)
            if best == nil || dist < best!.1 {
                best = (n, dist)
            }
        }
        return best?.0
    }

    private static func parseNumber(_ s: String) -> Int? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
                       .replacingOccurrences(of: ",", with: "")
        if let n = Int(trimmed), n >= 0 {
            return n
        }
        let lower = trimmed.lowercased()
        guard let last = lower.last, last == "k" || last == "m" || last == "b" else {
            return nil
        }
        let numPart = String(trimmed.dropLast())
        guard let d = Double(numPart) else { return nil }
        let multiplier: Double
        switch last {
        case "k": multiplier = 1_000
        case "m": multiplier = 1_000_000
        case "b": multiplier = 1_000_000_000
        default:  multiplier = 1
        }
        return Int(d * multiplier)
    }
}
