//
//  ContentView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/01/26.
//

import SwiftUI
import MapKit

struct WorkItem: Identifiable, Hashable, Codable {
    var id = UUID()
    
    let title: String
    let titleIcon: String
    let typeOfTransport: String
    let roads: String
    let lines: [String]
    let startDate: Date
    let endDate: Date
    let details: String
    let company: String
    
    enum CodingKeys: String, CodingKey {
        case title, titleIcon, typeOfTransport, roads, lines, startDate, endDate, details, company
    }
    
    var progress: Double {
        let now = Date()
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(startDate)
        let fraction = elapsed / total
        return min(max(fraction, 0), 1)
    }
}

struct ContentView: View {
    var body: some View {
        TabView{
            MainView()
                .tabItem{
                    Label("Home", systemImage: "house")
                }
            LinesView()
                .tabItem{
                    Label("Linee", systemImage: "arrow.branch")
                }
            SettingsView()
                .tabItem{Label("Impostazioni", systemImage: "gear")}
        }
        .tint(.red)
    }
}

struct MainView: View{
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @State private var closedStrike: Bool = false
    @State private var selectedFilter: FilterBy = .all
    @State private var searchInput: String = ""
    @StateObject private var viewModel = WorkViewModel()
    @FocusState private var isSearchFocused: Bool
    
    init() {
        _preferredFilter = AppStorage(wrappedValue: .all, "preferredFilter")
        _selectedFilter = State(initialValue: _preferredFilter.wrappedValue)
    }
    
    var filteredItems: [WorkItem] {
        let now = Date()
        let categoryFiltered: [WorkItem]
        let items = viewModel.items
        
        switch(selectedFilter){
            case .all:
                categoryFiltered = items
            case .bus:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("bus") }
            case .tram:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("tram") && $0.typeOfTransport != "tram.fill.tunnel"}
            case .metro:
                categoryFiltered = items.filter { $0.typeOfTransport.contains("tram.fill.tunnel")}
            case .train:
                categoryFiltered = items.filter{ $0.typeOfTransport.contains("train") }
            case .ATM:
                categoryFiltered = items.filter{ $0.company.contains("ATM") }
            case .Trenord:
                categoryFiltered = items.filter{ $0.company.contains("Trenord") }
            case .Movibus:
                categoryFiltered = items.filter{ $0.company.contains("Movibus") }
            case .STAV:
                categoryFiltered = items.filter{ $0.company.contains("STAV") }
            case .Autoguidovie:
                categoryFiltered = items.filter{ $0.company.contains("Autoguidovie") }
            case .scheduled:
                categoryFiltered = items.filter { $0.startDate > now }
            case .working:
                categoryFiltered = items.filter { $0.startDate <= now || $0.endDate <= now }
        }
        
        if searchInput.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { item in
                item.lines.contains { $0.localizedCaseInsensitiveContains(searchInput) }
            }
        }
    }

    var body: some View{
        NavigationStack{
            VStack(spacing: 0) {
                HStack {
                    Text("Lavori in corso")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.fetchWorks()
                        viewModel.fetchVariables()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 57)
                .padding(.bottom, 5)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cerca linea (es. S5, RE8)...", text: $searchInput)
                    .foregroundColor(.primary)
                    .autocorrectionDisabled(true)
                    .focused($isSearchFocused)
                    .submitLabel(.done)
                
                if !searchInput.isEmpty {
                    Button(action: {
                        searchInput = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            if(viewModel.strikeEnabled && !closedStrike){
                VStack(spacing: 8) {
                    Label("AVVISO SCIOPERO", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 25, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                   
                    Text("Sciopero proclamato per il \(viewModel.dateStrike).")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                   
                    Text("Le fasce garantite (06:00 - 09:00, 18:00 - 21:00) \(viewModel.guaranteed)")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("TextColor"))
                        .padding(.horizontal, 10)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text("Aderenti: \(viewModel.companiesStrikes)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color("TextColor"))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    }
                    Button(action:{
                        closedStrike = true
                    }){
                        Label("Chiudi", systemImage: "xmark")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterBy.allCases) { filter in
                        Button(action: {
                            withAnimation(.snappy){
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedFilter = filter
                            }
                        }){
                            Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                ZStack {
                                    if selectedFilter == filter {
                                        Capsule()
                                            .fill(.red)
                                    } else {
                                        Capsule()
                                            .stroke(Color.secondary, lineWidth: 1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedFilter == filter ? Color(.systemBackground) : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: filteredItems)
            .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 16){
                ScrollView{
                    LazyVStack(spacing: 12){
                        if viewModel.isLoading {
                            ProgressView("Caricamento in corso...")
                                .padding()
                            Spacer()
                            
                        } else if let error = viewModel.errorMessage {
                            VStack {
                                Image(systemName: "wifi.slash")
                                    .font(.largeTitle)
                                Text("Impossibile caricare i dati dal server.")
                                    .font(.title2)
                                Spacer()
                                Text("Controlla la tua connessione ad internet e riprova.").font(.title3).foregroundColor(.gray)
                                Button(action: {
                                    viewModel.fetchWorks()
                                })
                                {
                                    Label("Riprova", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    if(filteredItems.isEmpty){
                                        Text("Nessuna corrispondenza trovata.")
                                    }
                                    else{
                                        ForEach(filteredItems) { item in
                                            WorkInProgressRow(item: item)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .refreshable {
                                viewModel.fetchWorks()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .onAppear(){
                viewModel.fetchWorks()
                viewModel.fetchVariables()
                NotificationManager.shared.requestPermission()
            }
        }
    }
}

struct WorkInProgressRow: View {
    let item: WorkItem
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(item.details)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label(item.title, systemImage: item.titleIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
                
                Label(item.roads, systemImage: "mappin")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))

                HStack{
                    ForEach(item.lines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(getColor(for: line))
                            )
                    }
                }
                
                VStack(spacing: 6) {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .tint(item.progress == 1.0 ? .green : .red)

                    HStack {
                        let italianLoc = Date.FormatStyle(date: .abbreviated, time: .omitted)
                                .locale(Locale(identifier: "it_IT"))
                        
                        Text(item.startDate.formatted(italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                        Spacer()
                        Text(item.endDate.formatted(italianLoc))
                            .font(.caption)
                            .foregroundStyle(Color("TextColor"))
                    }
                    Spacer()
                    Text(item.company)
                        .foregroundStyle(Color("TextColor"))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct SettingsView: View{
    @State private var expandedTrenord = false
    @State private var expandedATM = false
    @State private var expandedATMLines = false
    @State private var presentedAlertReset = false
    
    //APP DATAS
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    
    let metroLines = ["M1", "M2", "M3", "M4", "M5"]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Preferiti"){
                    DisclosureGroup(isExpanded: $expandedTrenord){
                        HStack{
                            Label {
                                Text("Linee S")
                            } icon: {
                                Image("sLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if linesFavorites.contains("S") {
                                    linesFavorites.removeAll { $0 == "S" }
                                } else {
                                    linesFavorites.append("S")
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("S") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("S") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee R")
                            } icon: {
                                Image("rLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if linesFavorites.contains("R") {
                                    linesFavorites.removeAll { $0 == "R" }
                                } else {
                                    linesFavorites.append("R")
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("R") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("R") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label {
                                Text("Linee RE")
                            } icon: {
                                Image("reLinesIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if linesFavorites.contains("RE") {
                                    linesFavorites.removeAll { $0 == "RE" }
                                } else {
                                    linesFavorites.append("RE")
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("RE") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("RE") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee Trenord", systemImage: "train.side.front.car")
                    }
                    DisclosureGroup(isExpanded: $expandedATM){
                        DisclosureGroup(isExpanded: $expandedATMLines) {
                            ForEach(metroLines, id: \.self) { line in
                                LineFavouritesRow(line: line, favorites: $linesFavorites)
                            }
                        } label: {
                            Label("Linee Metro", systemImage: "tram.fill.tunnel")
                        }
                        HStack{
                            Label("Linee Tram", systemImage: "tram.fill")
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if linesFavorites.contains("Tram") {
                                    linesFavorites.removeAll { $0 == "Tram" }
                                } else {
                                    linesFavorites.append("Tram")
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Tram") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Tram") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Bus", systemImage: "bus.fill")
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if linesFavorites.contains("Bus") {
                                    linesFavorites.removeAll { $0 == "Bus" }
                                } else {
                                    linesFavorites.append("Bus")
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Bus") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Bus") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    label: {
                        Label("Linee ATM", systemImage: "tram.fill")
                    }
                }
                Section("Generali"){
                    Toggle(isOn: $enableNotifications){
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    Picker(selection: $preferredFilter){
                        ForEach(FilterBy.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    } label: {
                        Label("Filtro Predefinito", systemImage: "line.3.horizontal.decrease.circle.fill")
                    }
                    .pickerStyle(.navigationLink)
                }
                Section(footer: Text("Le impostazioni vengono salvate automaticamente.")) {
                    Button(role: .destructive) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        presentedAlertReset = true
                    } label: {
                        Label("Ripristina impostazioni", systemImage: "arrow.counterclockwise")
                    }
                }
                //* MARK: Notification Tests
                /*Section("Test"){
                    let test = WorkItem(
                        title: "Lavori Stradali", titleIcon: "tram", typeOfTransport: "tram", roads: "Via Negrelli", lines:["104", "67", "69"], startDate: Calendar.current.date(from: .init(year: 2026, month: 01, day: 06))!, endDate: Calendar.current.date(from: .init(year: 2026, month: 01, day: 07))!, details: "Picchio i Froci", company: "ATM"
                    )
                    
                    Button("Prova Notifica Programmata"){
                        NotificationManager.shared.scheduleWorkAlerts(for: test)
                    }
                    
                    Button("Prova Notifica Immediata"){
                        NotificationManager.shared.sendNotification()
                    }
                }*/
            }
            .navigationTitle("Impostazioni")
            .alert("Sei sicuro?", isPresented: $presentedAlertReset) {
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    enableNotifications = true
                    preferredFilter = .all
                    linesFavorites = []
                }
            } message: {
                Text("Sei sicuro di voler resettare?")
            }
        }
    }
}

struct LineFavouritesRow: View {
    let line: String
    @Binding var favorites: [String]
    
    var body: some View {
        HStack(spacing: 12) {
            Text(line)
                .foregroundStyle(.white)
                .font(.system(size: 12, weight: .bold))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getColor(for: line))
                )
            
            Text("Metro \(line)")
            
            Spacer()
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                if favorites.contains(line) {
                    favorites.removeAll { $0 == line }
                } else {
                    favorites.append(line)
                }
            }) {
                Image(systemName: favorites.contains(line) ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(favorites.contains(line) ? .orange : .gray)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct LineRow: View {
    let line: String
    let typeOfTransport: String
    let branches: String
    
    var body: some View {
        NavigationLink(destination: LineDetailView(lineName: line, typeOfTransport: typeOfTransport, branches: branches)){
            HStack(spacing: 12) {
                Text(line)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((typeOfTransport == "Tram") ? .orange :getColor(for: line))
                    )
                
                Text("\(typeOfTransport) \(line)")
            }
            .padding(.vertical, 4)
        }
    }
}

struct LinesView: View {
    let metros: [LineInfo] = [
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro"),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro"),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro"),
            LineInfo(name: "M4", branches: "Linate - San Cristoforo", type: "Metro"),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro")
        ]
    let trams = ["1", "2", "3", "4", "5", "7", "9", "10", "12", "14", "15", "16", "19", "24", "27", "31", "33"]
    
    var body: some View {
        NavigationStack{
            List{
                Section("Linee Metropolitane"){
                    ForEach(metros, id: \.id) { line in
                        LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches)
                    }
                }
                /*Section("Linee Tram"){
                    ForEach(trams, id: \.self) {tramLine in
                        LineRow(line: tramLine, typeOfTransport: "Tram")
                    }
                }*/
            }
            .navigationTitle("Linee")
        }
    }
}

struct LineDetailView: View {
    let lineName: String
    let typeOfTransport: String
    let branches: String
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Text(lineName)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((typeOfTransport == "Tram") ? .orange : getColor(for: lineName))
                            )
                        
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    
                    Divider()
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DIREZIONI:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text(branches)
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TEMPO DI ATTESA MEDIO:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text("3-7 Minuti")
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LAVORI SULLA LINEA:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text("0 attuali, 0 programmati.")
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .padding(.top, 20)
                .background(Color(uiColor: .systemBackground))
                
                
                Map(coordinateRegion: $region)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 100)
                    .ignoresSafeArea(edges: .bottom)
                
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//FILTERS
enum FilterBy: String, CaseIterable, Identifiable {
    case all = "Tutti"
    case bus = "Bus"
    case tram = "Tram"
    case metro = "Metropolitana"
    case train = "Treno"
    case working = "In Corso"
    case scheduled = "Programmati"
    case ATM = "di ATM"
    case Trenord = "di Trenord"
    case Movibus = "di Movibus"
    case STAV = "di STAV"
    case Autoguidovie = "di Autoguidovie"
    
    var id: String{self.rawValue}
}

struct LineInfo: Identifiable {
    let id = UUID()
    let name: String
    let branches: String
    let type: String
}

func getColor(for line: String) -> Color {
    switch line {
        //SUBURBAN LINES
        case "S1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "S2": return Color(red: 0, green: 152/255, blue: 121/255)
        case "S3": return Color(red: 169/255, green: 10/255, blue: 46/255)
        case "S4": return Color(red: 131/255, green: 187/255, blue: 38/255)
        case "S5": return Color(red: 243/255, green: 145/255, blue: 35/255)
        case "S6": return Color(red: 246/255, green: 210/255, blue: 0)
        case "S7": return Color(red: 229/255, green: 0, blue: 113/255)
        case "S8": return Color(red: 246/255, green: 182/255, blue: 182/255)
        case "S9": return Color(red: 162/255, green: 51/255, blue: 138/255)
        case "S11": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "S12": return Color(red: 44/255, green: 83/255, blue: 52/255)
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        
        //TILO LINES
        case "S10": return Color(red: 228/255, green: 35/255, blue: 19/255)
        case "S30": return Color(red: 0, green: 166/255, blue: 81/255)
        case "S40": return Color(red: 117/255, green: 188/255, blue: 118/255)
        case "S50": return Color(red: 131/255, green: 76/255, blue: 22/255)
        
        //METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        //BUS LINES
        case _ where line.contains("z"):
            return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains("Filobus"):
            return Color(red: 101/255, green: 179/255, blue: 46/255)
        
        //OTHER LINES
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case _ where line.contains("R"):
                return Color.blue
            
        default: return Color.gray
    }
}

//EXTENSION: Save files also with arrays

extension Array: RawRepresentable where Element == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension WorkItem {
    func matchesFavorites(_ favorites: [String]) -> Bool {
        
        if favorites.contains("Bus") && self.typeOfTransport.contains("bus") { return true }
        if favorites.contains("Tram") && self.typeOfTransport.contains("tram") { return true }

        for line in self.lines {
            if favorites.contains(line) { return true }
            if favorites.contains("S") && line.hasPrefix("S") && line.dropFirst().allSatisfy({ $0.isNumber }) { return true }
            if favorites.contains("R") && line.hasPrefix("R") && !line.hasPrefix("RE") { return true }
            if favorites.contains("RE") && line.hasPrefix("RE") { return true }
        }
        
        return false
    }
}

#Preview {
    ContentView()
}

