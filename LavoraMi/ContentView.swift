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
    @StateObject private var viewModel = WorkViewModel()
    
    var body: some View {
        TabView{
            MainView(viewModel: viewModel)
                .tabItem{
                    Label("Home", systemImage: "house")
                }
            LinesView(viewModel: viewModel)
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
    @ObservedObject var viewModel: WorkViewModel
    @FocusState private var isSearchFocused: Bool
    
    init(viewModel: WorkViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
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
                categoryFiltered = items.filter { $0.startDate <= now && $0.endDate >= now }
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
    @StateObject private var viewModel = WorkViewModel()
    
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
                Section("Informazioni"){
                    NavigationLink(destination: InfoView()){
                        Label("Fonti & Sviluppo", systemImage: "person.crop.circle.badge.questionmark")
                    }
                    HStack{
                        Label("Versione", systemImage: "info.circle.fill")
                        Spacer()
                        Text("\(Bundle.main.shortVersion)")
                    }
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
                Text("Sei sicuro di voler ripristinare le impostazioni?")
            }
        }
    }
}

struct InfoView: View {
    var body: some View {
        Section{
            HStack{
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("LavoraMi")
                    .font(.system(size: 35))
                    .bold()
            }
            Text(Bundle.main.shortVersion)
            Divider()
            ScrollView{
                Section(){
                    Text("Fonti Dati")
                        .font(.system(size: 30))
                        .bold()
                    Text("Questa applicazione aggrega dati pubblici, accessibili a tutti, per facilitarne la consultazione.")
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .italic()
                    Text("""
                    LavoraMi è un'applicazione indipendente sviluppata da terze parti e NON è in alcun modo affiliata, supportata, autorizzata o sponsorizzata da ATM S.p.A., Trenord S.r.l., Gruppo FNM, RFI o altri enti di trasporto citati.

                    Tutti i dati visualizzati in questa applicazione (orari, stati del servizio, avvisi) sono raccolti da fonti pubbliche ed elaborati automaticamente al solo scopo di migliorarne la comprensione e la leggibilità per l'utente finale.
                    
                    Non si fornisce alcuna garanzia, esplicita o implicita, riguardo l'accuratezza, la completezza, l'affidabilità o la tempestività delle informazioni fornite. Le informazioni potrebbero non riflettere variazioni dell'ultimo minuto.

                    L'uso dell'applicazione è interamente a proprio rischio. Lo sviluppatore declina ogni responsabilità per eventuali inesattezze, ritardi, mancati servizi, danni diretti o indiretti derivanti dall'affidamento sulle informazioni fornite da questa app.
                    
                    Per le decisioni di viaggio critiche, si raccomanda di fare sempre riferimento ai canali ufficiali, agli annunci sonori e alla segnaletica presente in stazione.
                    
                    Tutti i marchi, i loghi e i nomi commerciali citati appartengono ai legittimi proprietari.
                    """)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                }
                Divider()
                Section(){
                    VStack(spacing: 12){
                        Text("Team di Sviluppo")
                            .font(.system(size: 30))
                            .bold()
                            .padding(.top, 20)
                        
                        Text("Sviluppatore iOS:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatore Android:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Tommaso Ruggeri")
                            .bold()
                            .font(.system(size: 25))
                    }
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Contatti")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    
                    Link(destination: URL(string: "mailto:help.playepik@gmail.com")!) {
                        Label("Segnala un bug", systemImage: "ladybug.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.bottom, 10)
                    Spacer()
                }
            }
        }
    }
}

struct LineFavouritesRow: View {
    let line: String
    @Binding var favorites: [String]
    @StateObject private var viewModel = WorkViewModel()
    
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
    let waitMinutes: String
    let stations: [MetroStation]
    @ObservedObject var viewModel: WorkViewModel
    
    var body: some View {
        NavigationLink(destination: LineDetailView(lineName: line, typeOfTransport: typeOfTransport, branches: branches, waitMinutes: waitMinutes, workScheduled: getWorkScheduled(line: line, viewModel: viewModel), workNow: getWorkNow(line: line, viewModel: viewModel), stations: stations)){
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
    @ObservedObject var viewModel: WorkViewModel
    
    var metros: [LineInfo] {
        [
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro", waitMinutes: "Sesto FS: 3 min | Rho/Bisceglie: 7-8 min.", stations: StationsDB.stationsM1),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro", waitMinutes: "Gessate / Cologno: 12-15 min | Assago / Abbiategrasso: 9-10 min", stations: StationsDB.stationsM2),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro", waitMinutes: "4-5 min.", stations: StationsDB.stationsM3),
            LineInfo(name: "M4", branches: "Linate - San Cristoforo", type: "Metro", waitMinutes: "2-3 min.",stations: StationsDB.stationsM4),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro", waitMinutes: "4 min.", stations: StationsDB.stationsM5)
        ]
    }
    
    var suburban: [LineInfo] {
        [
            LineInfo(name: "S1", branches: "Saronno - Lodi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS1),
            LineInfo(name: "S2", branches: "Mariano Comense - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS2),
            LineInfo(name: "S3", branches: "Saronno - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS3),
            LineInfo(name: "S4", branches: "Camnago - Milano Cadorna", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS4),
            LineInfo(name: "S5", branches: "Varese - Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS5),
            LineInfo(name: "S6", branches: "Novara - Pioltello Limito/Treviglio", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS6),
            LineInfo(name: "S7", branches: "Lecco - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "1 ora - 30 min.", stations: StationsDB.stationsS7),
            LineInfo(name: "S8", branches: "Lecco - Carnate - Milano Pta Garibaldi", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS8),
            LineInfo(name: "S9", branches: "Saronno - Albairate Vermezzo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS9),
            LineInfo(name: "S11", branches: "Rho - Como S. Giovanni", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS11),
            LineInfo(name: "S12", branches: "Melegnano - Cormano", type: "Suburbano", waitMinutes: "30 min (solo in settimana il servizio è attivo).", stations: StationsDB.stationsS12),
            LineInfo(name: "S13", branches: "Pavia - Milano Bovisa", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS13),
            LineInfo(name: "S19", branches: "Albairate Vermezzo - Milano Rogoredo", type: "Suburbano", waitMinutes: "30 min.", stations: StationsDB.stationsS19),
            LineInfo(name: "S31", branches: "Brecia - Iseo", type: "Suburbano", waitMinutes: "1 ora.", stations: StationsDB.stationsS31)
        ]
    }
    
    var body: some View {
        NavigationStack{
            List{
                Section("Linee Metropolitane"){
                    ForEach(metros, id: \.id) { line in
                        LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                    }
                }
                Section("Linee Suburbane"){
                    ForEach(suburban, id: \.id) { line in
                        LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, stations: line.stations, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Linee")
        }
    }
}

func getWorkNow(line: String, viewModel: WorkViewModel) -> Int{
    let now = Date()
    
    return viewModel.items.filter {
        ($0.startDate <= now && $0.endDate >= now) && $0.lines.contains(line)}.count
}

func getWorkScheduled(line: String, viewModel: WorkViewModel) -> Int{
    let now = Date()
    
    return viewModel.items.filter{($0.startDate > now) && $0.lines.contains(line)}.count
}

struct LineDetailView: View {
    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    
    let workScheduled: Int
    let workNow: Int
    
    let stations: [MetroStation]
    
    private var centerIndex: Int { max(0, stations.count / 2) }
    private var centerCoordinate: CLLocationCoordinate2D {
        stations.isEmpty ? CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927) : stations[centerIndex].coordinate
    }
    
    private var lombardyBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2.5)
            ),
            minimumDistance: 1000,
            maximumDistance: 175000
        )
    }
    
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
                        
                        Text(waitMinutes)
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                        
                        if(lineName == "S2" || lineName == "S12" || lineName == "S19"){
                            Text("LA LINEA E' ATTIVA SOLO NEI GIORNI SETTIMANALI.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LAVORI SULLA LINEA:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        
                        Text("\(workNow) attuali, \(workScheduled) programmati.")
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
                
                
                Map(initialPosition: .region(MKCoordinateRegion(
                        center: centerCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                    )),
                    bounds: lombardyBounds
                    ){
                        let lineColor: Color = getColor(for: lineName)
                        switch(lineName){
                            case "M1":
                                MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                                let pagano = stations.first(where: { $0.name == "Pagano" })!
                                let rhoBranch = [pagano] + stations.filter { $0.branch == "Rho" }
                                MapPolyline(coordinates: rhoBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                                
                                let bisceglieBranch = [pagano] + stations.filter { $0.branch == "Bisceglie" }
                                MapPolyline(coordinates: bisceglieBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                            
                                ForEach(stations) { station in
                                    Annotation(station.name, coordinate: station.coordinate) {
                                        ZStack {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 12, height: 12)
                                            Circle()
                                                .stroke(lineColor, lineWidth: 3)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                            case "M2":
                                MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                                let famagosta = stations.first(where: { $0.name == "Famagosta" })!
                                let assagoBranch = [famagosta] + stations.filter { $0.branch == "Assago" }
                                MapPolyline(coordinates: assagoBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                                
                                let abbiategrassoBranch = [famagosta] + stations.filter { $0.branch == "Abbiategrasso" }
                                MapPolyline(coordinates: abbiategrassoBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)

                                let cascinaGobba = stations.first(where: { $0.name == "Cascina Gobba" })!
                                let colognoBranch = [cascinaGobba] + stations.filter { $0.branch == "Cologno" }
                                MapPolyline(coordinates: colognoBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                                
                                let gessateBranch = [cascinaGobba] + stations.filter { $0.branch == "Gessate" }
                                MapPolyline(coordinates: gessateBranch.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                            
                                ForEach(stations) { station in
                                    Annotation(station.name, coordinate: station.coordinate) {
                                        ZStack {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 12, height: 12)
                                            Circle()
                                                .stroke(lineColor, lineWidth: 3)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }

                            default:
                                MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                    .stroke(lineColor, lineWidth: 5)
                            
                                ForEach(stations) { station in
                                    Annotation(station.name, coordinate: station.coordinate) {
                                        ZStack {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 12, height: 12)
                                            Circle()
                                                .stroke(lineColor, lineWidth: 3)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 100)
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .ignoresSafeArea(edges: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
}

//NOTE: FILTERS
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
    let waitMinutes: String
    let stations: [MetroStation]
}

struct MetroStation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let branch: String
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
        case "S12": return .black
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        case "S19": return Color(red: 102/255, green: 13/255, blue: 54/255)
        case "S31": return .gray
        
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
            if favorites.contains("Tram") && self.typeOfTransport.lowercased().contains("tram") {
                return true
            }
            if favorites.contains("Bus") && self.typeOfTransport.lowercased().contains("bus") {
                return true
            }
            
            for workLine in self.lines {
                if favorites.contains(workLine) { return true }
                if favorites.contains("S") && workLine.hasPrefix("S") {
                    let suffix = workLine.dropFirst()
                    if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) { return true }
                }
                
                if favorites.contains("R") && workLine.hasPrefix("R") && !workLine.hasPrefix("RE") {
                    return true
                }
                if favorites.contains("RE") && workLine.hasPrefix("RE") {
                    return true
                }
            }
            
            return false
        }
}

// MARK: - Bundle version helpers
extension Bundle {
    /// CFBundleShortVersionString (e.g., 1.2.3)
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// CFBundleVersion (build number)
    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

#Preview {
    ContentView()
}

