//
//  GTFSHelper.swift
//  LavoraMi
//
//  Created by Andrea Filice on 21/04/2026.
//

import Foundation

struct GTFSRoute: Codable {
    let route: String
    let headsigns: [String]
    let services: [String: GTFSService]
    let stops: [String: GTFSStop]
}

struct GTFSService: Codable {
    let id: String
    let dates: [String]
}

struct GTFSStop: Codable {
    let n: String
    let d: [String: [[AnyDecodable]]]
}

struct AnyDecodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else { value = "" }
    }
    
    func encode(to encoder: Encoder) throws {}
}

struct Departure: Identifiable {
    let id = UUID()
    let time: String
    let headsign: String
    let minutesFromNow: Int

    var formattedWait: String {
        guard minutesFromNow >= 60 else { return "\(minutesFromNow) min" }
        let hours = minutesFromNow / 60
        let mins = minutesFromNow % 60
        return mins == 0 ? "\(hours) h" : "\(hours) h \(mins) min"
    }
}

struct GTFSHelper {
    static func load(from url: URL) async throws -> GTFSRoute {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GTFSRoute.self, from: data)
    }

    static func getDepartures(for stopId: String, in route: GTFSRoute, limit: Int = 10) -> [String: [Departure]]? {
        guard let stop = route.stops[stopId] else { return nil }
        
        let today = todayString()
        let nowMins = nowMinutes()
        
        let activeServiceIds = Set(route.services.filter { $0.value.dates.contains(today) }.map { $0.value.id })
        
        var serviceIdByIndex: [Int: String] = [:]
        for (key, svc) in route.services {
            if let idx = Int(key) {
                serviceIdByIndex[idx] = svc.id
            }
        }
        
        var result: [String: [Departure]] = [:]
        
        for (directionId, departuresList) in stop.d {
            var dirDepartures: [Departure] = []
            
            for entry in departuresList {
                guard entry.count >= 3,
                      let timeStr = entry[0].value as? String,
                      let headsignIdx = entry[1].value as? Int,
                      let serviceIdx = entry[2].value as? Int else { continue }
                
                guard let serviceId = serviceIdByIndex[serviceIdx],
                      activeServiceIds.contains(serviceId) else { continue }
                
                let parts = timeStr.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2 else { continue }
                let departureMinutes = parts[0] * 60 + parts[1]
                
                let diff = departureMinutes - nowMins
                guard diff >= 0 else { continue }
                
                let headsign = headsignIdx < route.headsigns.count ? route.headsigns[headsignIdx] : "Direzione ignota"
                
                dirDepartures.append(Departure(
                    time: timeStr,
                    headsign: headsign,
                    minutesFromNow: diff
                ))
                
                if dirDepartures.count >= limit { break }
            }
            
            if !dirDepartures.isEmpty {
                result[directionId] = dirDepartures
            }
        }
        
        return result.isEmpty ? nil : result
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "Europe/Rome")
        return f.string(from: Date())
    }

    private static func nowMinutes() -> Int {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Rome")!
        let now = Date()
        return cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    }
}
