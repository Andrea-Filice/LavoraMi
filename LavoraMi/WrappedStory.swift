//
//  WrappedStory.swift
//  LavoraMi
//
//  Created by Andrea Filice on 01/09/2026.
//

import Foundation

struct WrappedStory: Identifiable, Hashable {
    let id: Int
    let videoResourceName: String
    let videoExtension: String
    let subdirectory: String?

    init(id: Int, videoResourceName: String, videoExtension: String = "mp4", subdirectory: String? = "Video") {
        self.id = id
        self.videoResourceName = videoResourceName
        self.videoExtension = videoExtension
        self.subdirectory = subdirectory
    }
    
    var videoURL: URL? {
        if let subdirectory,
           let url = Bundle.main.url(forResource: videoResourceName, withExtension: videoExtension, subdirectory: subdirectory) {
            return url
        }

        if let url = Bundle.main.url(forResource: videoResourceName, withExtension: videoExtension) {
            return url
        }

        return WrappedStory.recursiveSearch(fileName: "\(videoResourceName).\(videoExtension)")
    }
    private static func recursiveSearch(fileName: String) -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil)

        while let candidate = enumerator?.nextObject() as? URL {
            if candidate.lastPathComponent == fileName {
                return candidate
            }
        }

        return nil
    }
}

extension WrappedStory {
    static func debugPrintBundleVideos() {
        guard let resourceURL = Bundle.main.resourceURL else {
            print("Il bundle non è stato trovato.")
            return
        }

        let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil)
        var found: [String] = []
        while let candidate = enumerator?.nextObject() as? URL {
            if candidate.pathExtension.lowercased() == "mp4" {
                found.append(candidate.path.replacingOccurrences(of: resourceURL.path, with: ""))
            }
        }

        if found.isEmpty {print("Nessun file .mp4 trovato.")}
        else {found.forEach { print("   \($0)") }}
    }
}

extension WrappedStory {
    static let augustStories: [WrappedStory] = (1...5).map {
        WrappedStory(id: $0 - 1, videoResourceName: "august_story\($0)")
    }
}
