//
//  SharedData.swift
//  LavoraMi
//
//  Created by Andrea Filice on 17/01/26.
//

import Foundation
import WidgetKit

struct SavedLine: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let longName: String
    let iconTransport: String
    let worksNow: Int
    let worksScheduled: Int
    let isDeviatedLine: Bool
    
    static let empty = SavedLine(id: "empty", name: "empty", longName: "", iconTransport: "", worksNow: 0, worksScheduled: 0, isDeviatedLine: false)
}

final class DataManager {
    static let shared = DataManager()
    private let groupName = "group.com.lavorami.lavoramiapp"
    private let key = "favouriteLine"
    private let openWidgetLineKey = "openWidgetLine"
    
    private let defaults = UserDefaults(suiteName: "group.com.lavorami.lavoramiapp")

    func setSavedLine(_ line: SavedLine) {
        if let encoded = try? JSONEncoder().encode(line) {
            defaults?.set(encoded, forKey: key)
            defaults?.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func getSavedLine() -> SavedLine? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedLine.self, from: data)
    }
    
    func deleteSavedLine() {
        setSavedLine(.empty)
    }
    
    func setOpenWidgetLine(_ value: Bool) {
        defaults?.set(value, forKey: openWidgetLineKey)
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func getOpenWidgetLine() -> Bool {
        defaults?.synchronize()
        guard defaults?.object(forKey: openWidgetLineKey) != nil else {
            return true
        }
        return defaults?.bool(forKey: openWidgetLineKey) ?? true
    }
}
