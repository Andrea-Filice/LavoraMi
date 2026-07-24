//
//  LavoraMiWidget.swift
//  LavoraMiWidget
//
//  Created by Andrea Filice on 17/01/26.
//

import WidgetKit
import SwiftUI
import UIKit
import ImageIO

struct WorkEntry: TimelineEntry {
    let date: Date
    let linea: SavedLine?
    let stato: String
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (WorkEntry) -> Void) {
        let entry = WorkEntry(date: Date(), linea: SavedLine(id: "0", name: "M1", longName: "Metro", iconTransport: "tram.fill.tunnel", worksNow: 0, worksScheduled: 2), stato: "Anteprima")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkEntry>) -> Void) {
        let savedLine = DataManager.shared.getSavedLine()
        let isInvalid = (savedLine == nil || savedLine?.id == "empty" || savedLine?.id == "EMPTY" || savedLine?.id == "0")
        
        if isInvalid {
            let entry = WorkEntry(date: Date(), linea: nil, stato: "empty")
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }
        
        if let line = savedLine {
            Task {
                let counts = await WidgetNetworkManager.fetchCounts(for: line.name)
                
                let updatedLine = SavedLine(
                    id: line.id,
                    name: line.name,
                    longName: line.longName,
                    iconTransport: line.iconTransport,
                    worksNow: counts.0,
                    worksScheduled: counts.1
                )
                
                let entry = WorkEntry(date: Date(), linea: updatedLine, stato: "def")
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                
                completion(timeline)
            }
        }
    }

    func placeholder(in context: Context) -> WorkEntry {
        WorkEntry(date: Date(), linea: SavedLine(id: "empty", name: "1", longName: "2", iconTransport: "", worksNow: 0, worksScheduled: 0), stato: "empty")
    }
}

struct LavoraMiWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        if(entry.stato == "empty") {
            VStack(alignment: .leading, spacing: 12) {
                HStack{
                    lineBadge(name: "M1")
                    lineBadge(name: "S5")
                    if (family == .systemMedium) {
                        lineBadge(name: "M3")
                        lineBadge(name: "S2")
                        lineBadge(name: "z620")
                    }
                }
                
                Text("Seleziona una linea in app da mostrare nel Widget.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    lineBadge(name: entry.linea?.name ?? "err")
                    
                    Spacer()
                    
                    Image(systemName: entry.linea?.iconTransport ?? "tram.fill")
                        .foregroundColor(.secondary)
                }
                Text("\(entry.linea?.longName ?? "") \(entry.linea?.name ?? "")")
                    .bold()
                    .font(.system(size: 15))
                Divider()
                HStack(spacing: 2) {
                    Label("IN CORSO", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(entry.linea?.worksNow ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 2) {
                    Label("PROGRAMMATI", systemImage: "calendar")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("\(entry.linea?.worksScheduled ?? 0)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    func lineBadge(name: String) -> some View {
        if renderingMode == .accented {
            Text(name)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary, lineWidth: 2)
                )
        }
        else {
            Text(name)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getColor(for: name))
                )
        }
    }
}

struct LavoraMiWidget: Widget {
    let kind: String = "LavoraMiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LavoraMiWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(deepLinkURL(for: entry))
            } else {
                LavoraMiWidgetEntryView(entry: entry)
                    .padding()
                    .background()
                    .widgetURL(deepLinkURL(for: entry))
            }
        }
        .configurationDisplayName("Stato Linea")
        .description("Mostra lo stato della linea selezionata.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    private func deepLinkURL(for entry: WorkEntry) -> URL? {
        guard entry.stato != "empty", let name = entry.linea?.name, !name.isEmpty else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "lavorami"
        components.host = "linea"
        components.queryItems = [URLQueryItem(name: "nome", value: name)]
        
        return components.url
    }
}

class WidgetNetworkManager {
    static func fetchCounts(for lineName: String) async -> (Int, Int) {
        let urlString = "https://cdn.lavorami.it/lavoriAttuali.json"
        guard let url = URL(string: urlString) else { return (0, 0) }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let works = try decoder.decode([WorkItem].self, from: data)
            let now = Date()

            let activeWorks = works.filter { work in
                work.lines.contains(lineName) &&
                work.startDate <= now &&
                work.endDate >= now
            }
            
            let scheduledWorks = works.filter { work in
                work.lines.contains(lineName) &&
                work.startDate > now
            }
            
            return (activeWorks.count, scheduledWorks.count)
            
        } catch {
            print("Errore Widget: \(error)")
            return (0, 0)
        }
    }
}

#Preview(as: .systemMedium) {
    LavoraMiWidget()
} timeline: {
    WorkEntry(date: Date(), linea: SavedLine(id: "M1", name: "M1", longName: "Metro", iconTransport: "", worksNow: 1, worksScheduled: 2), stato: "empty")
}
