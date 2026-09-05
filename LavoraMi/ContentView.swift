//
//  ContentView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 05/01/26.
//

import SwiftUI
import MapKit
import SafariServices
import WidgetKit
import LocalAuthentication
import SwiftUIMailView
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseMessaging
import Translation
import StoreKit
import Combine
import SystemConfiguration
import CoreLocation
import FoundationModels

internal import Auth

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

//MARK: MAIN VIEW
struct ContentView: View {
    @StateObject private var viewModel = WorkViewModel()
    @Binding var showSetupScreen: Bool
    @State private var showUpdatePopUp: Bool = false
    @State private var selectedTab: Int = 0
    @State private var deepLinkedLine: DeepLinkLine? = nil
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showWhatsNewScreen") var showWhatsNewScreenToggle: Bool = true

    @Environment(\.openURL) private var openURLAction

    var body: some View {
        TabView(selection: $selectedTab){
            MainView(viewModel: viewModel)
                .tabItem {Label("Home", image: "homeIcon")}
                .tag(0)
            LinesView(viewModel: viewModel)
                .tabItem{Label("Linee", systemImage: "arrow.branch")}
                .tag(1)
            SettingsView(viewModel: viewModel)
                .tabItem{Label("Impostazioni", systemImage: "gear")}
                .tag(2)
        }
        .tint(.red)
        .onChange(of: selectedTab) {
            if(feedbacksEnabled){
                HapticManager.shared.trigger()
            }
        }
        .sheet(isPresented: $showSetupScreen){
            SetupView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openLineDetailFromWidget)) { notification in
            guard let nome = notification.object as? String else { return }
            selectedTab = 1
            deepLinkedLine = DeepLinkLine(name: nome)
        }
        .fullScreenCover(item: $deepLinkedLine) { link in
            DeepLinkLineDetailWrapper(lineName: link.name, viewModel: viewModel)
        }
    }
}

struct SetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @State private var currentPage = 0
    @State private var showPopUpConfirmSkipSetup: Bool = false
    @StateObject private var locationManager = LocationManager()
    
    let pages = [
        SetupPage(
            title: "Benvenuto su LavoraMi",
            description: "Tieniti informato. Prima e durante il tuo viaggio.",
            transitionImage: "1",
            standardImage: "1",
            fallbackImage: "lightrail.fill"
        ),
        SetupPage(
            title: "Pianifica il Viaggio",
            description: "Pianifica il tuo viaggio sapendo dei disagi sul tragitto, ben prima di partire.",
            transitionImage: "mappin",
            standardImage: "mappin.and.ellipse"
        ),
        SetupPage(
            title: "Tieni sott'occhio i lavori",
            description: "Seleziona una linea da poter mostrare nel Widget per tenerla sempre sott'occhio.",
            transitionImage: "star.fill",
            standardImage: "widget.small",
            fallbackImage: "star.fill"
        ),
        SetupPage(
            title: "Tieniti Aggiornato",
            description: "Attiva le notifiche per rimanere al passo coi lavori. Senza perderti sorprese.",
            transitionImage: "bell.slash.fill",
            standardImage: "bell.fill"
        ),
        SetupPage(
            title: "Traduci i lavori, nella lingua che vuoi tu.",
            description: "Traduci i dettagli dei lavori in altre lingue, basta cliccare sui dettagli del lavoro e cliccare \"Traduci\".",
            transitionImage: "text.append",
            standardImage: "translate"
        ),
        SetupPage(
            title: "Non perderti Mai.",
            description: "Attiva la posizione per sapere sempre dove sei e non perdere mai la tua fermata.",
            transitionImage: "map.fill",
            standardImage: "location.fill"
        ),
        SetupPage(
            title: "Accessibile, sempre.",
            description: "Guarda se una linea è completamente, parzialmente o per nulla accessibile. Tutto a colpo d'occhio.",
            transitionImage: "person.fill",
            standardImage: "figure.roll"
        ),
        SetupPage(
            title: "Tu ed ancora Tu.",
            description: "I tuoi dati sono al sicuro. Crea un Account per registrarti al nostro club LavoraMi.",
            transitionImage: "lock.open.fill",
            standardImage: "lock.fill"
        ),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0 ..< pages.count, id: \.self) { index in
                        SetupPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldPage, newPage in
                    if newPage == 3 {
                        NotificationManager.shared.requestPermission()
                    }
                    if newPage == 5 {
                        locationManager.requestPermission()
                    }
                }
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color("TextColor") : Color.gray.opacity(0.4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                Spacer()
                if currentPage == pages.count - 1 {
                    Button {
                        hasNotCompletedSetup = false
                        dismiss()
                    } label: {
                        Text("Fine")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Avanti")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(Text("LavoraMi"))
            .toolbar {
                if(currentPage != pages.count - 1) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPopUpConfirmSkipSetup = true
                        } label: {
                            Text("Salta")
                        }
                    }
                }
            }
            .alert("Sei sicuro?", isPresented: $showPopUpConfirmSkipSetup){
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    hasNotCompletedSetup = false; dismiss()
                }
            } message: {
                Text("Sei sicuro di voler saltare la configurazione?")
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
        NotificationManager.shared.requestPermission()
        locationManager.requestPermission()
    }
}

struct ObsoleteVersionView: View {
    @State private var showSetupScreen: Bool = true
    @StateObject private var viewModel = WorkViewModel()
    @Environment(\.openURL) private var openURLAction
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("icon")
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .font(.system(size: 10))
                .foregroundColor(Color("TextColor"))
            
            Text("Stai usando una versione obsoleta.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("Stai usando una versione non più supportata di LavoraMi, aggiorna all'ultima versione disponibile per avere accesso a nuove funzionalità e risolvere problemi.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            Text("Ultima versione supportata: \(viewModel.minimumVersion).")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            Button {
                let url = URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!
                openURLAction(url)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward")
                    Text("Aggiorna ora")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.top, 25)
            
            Spacer()
        }
        .onAppear(){
            viewModel.fetchRequirements()
        }
    }
}

// MARK: MAINTENANCE VIEW
struct MaintenanceView: View {
    var maintenanceDeps: String = ""
    var maintenanceDepsEn: String = ""
    var maintenanceDepsEs: String = ""
    var onResolved: () -> Void = {}
    
    @State private var showSetupScreen: Bool = true
    @StateObject private var viewModel = WorkViewModel()
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(Color("TextColor"))
            
            Text("Manutenzione in corso.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("I server di LavoraMi non sono attualmente disponibili. Ci scusiamo per il disagio.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            
            if !maintenanceDeps.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("it") == true {
                Text(maintenanceDeps)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            else if !maintenanceDepsEn.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("en") == true {
                Text(maintenanceDepsEn)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            else if !maintenanceDepsEs.isEmpty && Bundle.main.preferredLocalizations.first?.hasPrefix("es") == true {
                Text(maintenanceDepsEs)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            
            Button {
                guard !isLoading else { return }
                isLoading = true
                
                viewModel.fetchRequirements {
                    if (!viewModel.maintenanceModeEnabled){
                        onResolved()
                    }
                    
                    stopLoading()
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Caricamento..." : "Riprova")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isLoading ? Color.gray : Color.red)
                .cornerRadius(8)
            }
            .padding(.top, 25)
            
            Spacer()
        }
    }
    
    func stopLoading() {
        isLoading = false
    }
}

struct SetupPage {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let transitionImage: String
    let standardImage : String
    var fallbackImage: String? = nil
}

struct SetupPageView: View {
    @State var startImageTransition : Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @AppStorage("enableAnimations") var enableAnimations = true
    let page: SetupPage

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 18.0, *), enableAnimations {
                if(page.standardImage != "1") {
                    Image(systemName: (startImageTransition) ? page.standardImage : page.transitionImage)
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear{
                            Task{
                                try? await Task.sleep(for: .seconds(1))
                                withAnimation{
                                    startImageTransition = true
                                }
                            }
                        }
                        .onDisappear{
                            startImageTransition = false
                        }
                }
                else {
                    let images = ["tram.fill", "tram.fill.tunnel", "lightrail.fill", "bus.fill"]

                    Image(systemName: images[i])
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 50)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                        .onAppear {
                            imageTransitionFirstPage = true
                            Task {
                                while imageTransitionFirstPage {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        i = (i + 1) % images.count
                                    }
                                }
                            }
                        }
                        .onDisappear(){
                            imageTransitionFirstPage = false
                        }
                }
            }
            else{
                Image(systemName: page.fallbackImage ?? page.standardImage)
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 50)
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if(page.title == "Tu ed ancora Tu."){
                Text("Creando un Account LavoraMi, accetti i Termini di Servizio e la Privacy Policy. Vai in Impostazioni > Account per saperne di più.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            else if(page.title == "Traduci i lavori, nella lingua che vuoi tu."){
                Text("Per attivare questa Funzionalità anche in lingua Italiana, Vai in Impostazioni > Opzioni Avanzate ed attiva \"Mostra Pulsante Traduci\".")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

struct MainView: View {
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    
    @State private var closedStrike: Bool = false
    @State private var selectedFilter: FilterBy = .all
    @State private var searchInput: String = ""
    @State private var alreadyRefreshed: Bool = false
    @State private var adsRequested: Bool = false
    @State private var showInfoFavoriteLines: Bool = false
    @State private var showMaintenanceMode: Bool = false
    @State private var strikeExpanded: Bool = true
    @AppStorage("hasOpenedWrapped") private var hasOpenedWrapped: Bool = false
    @State private var showWrapped: Bool = false
    @State private var showWrappedOpenedInfo: Bool = false
    @State private var livePulse = true
    @State private var suggestedTrigger = 0
    @State private var marqueeOffset: CGFloat = 0
    @State private var marqueeContainerWidth: CGFloat = 0
    @State private var marqueeId = UUID()
    
    @ObservedObject var viewModel: WorkViewModel
    @StateObject var authManager = AuthManager()
    @StateObject var adMobManager = AdMobManager()
    @ObservedObject var consentManager = ConsentManager.shared
    @FocusState private var isSearchFocused: Bool
    @State private var currentHintIndex: Int = 0
    
    private let searchHints = [
        String(localized: .cercaNeiLavori),
        String(localized: .scopriQualcosaDiNuovo),
        String(localized: .cercaLaTuaLinea),
        String(localized: .cercaCiòCheAmi),
        String(localized: .nonEssereLultimoASapereLeCose),
        String(localized: .scopriLeNovità),
        String(localized: .lavoriDellaSettimana)
    ]
    
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
            case .suggested:
                categoryFiltered = items.filter { item in
                    linesSelected.contains { item.lines.contains($0) }
                }
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
            case .Tilo:
                categoryFiltered = items.filter{ $0.company.contains("TILO") }
            case .Movibus:
                categoryFiltered = items.filter{ $0.company.contains("Movibus") }
            case .Net:
                categoryFiltered = items.filter{ $0.company.contains("NET") }
            case .STAV:
                categoryFiltered = items.filter{ $0.company.contains("STAV") }
            case .STAR:
                categoryFiltered = items.filter { $0.company.contains("STAR") }
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
                let matchLines = item.lines.contains { $0.localizedCaseInsensitiveContains(searchInput) }
                let matchRoads = item.roads.localizedCaseInsensitiveContains(searchInput)
                let matchDetails = item.details.localizedCaseInsensitiveContains(searchInput)
                
                return matchLines || matchRoads || matchDetails
            }
        }
    }

    var body: some View {
        NavigationStack{
            MainHeaderView(viewModel: viewModel, showMaintenanceMode: $showMaintenanceMode)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                ZStack(alignment: .leading) {
                    if searchInput.isEmpty && !isSearchFocused {
                        Text(searchHints[currentHintIndex])
                            .foregroundColor(.gray.opacity(0.55))
                            .allowsHitTesting(false)
                            .id(currentHintIndex)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    TextField("", text: $searchInput)
                        .foregroundColor(.primary)
                        .autocorrectionDisabled(true)
                        .focused($isSearchFocused)
                        .submitLabel(.done)
                }
                
                if !searchInput.isEmpty {
                    Button(action: {
                        searchInput = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 5)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentHintIndex = (currentHintIndex + 1) % searchHints.count
                    }
                }
            }
            if viewModel.wrappedEnabled && !hasOpenedWrapped {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    showWrapped = true
                }) {
                    HStack(spacing: 8) {
                        Image("iconAppAndroid")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 5))

                        Text("SCOPRI IL WRAPPED DI QUESTO MESE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(0.5)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(red: 224/255, green: 32/255, blue: 34/255))
                }
                .buttonStyle(.plain)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            if viewModel.strikeEnabled && showStrikeBanner {
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(duration: 0.3)) {
                            closedStrike.toggle()
                        }
                        if feedbacksEnabled { HapticManager.shared.trigger() }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("AVVISO SCIOPERO")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(0.5)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .rotationEffect(.degrees(closedStrike ? -90 : 0))
                                .animation(.spring(duration: 0.3), value: closedStrike)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.red)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            Text("Sciopero proclamato per il **\(viewModel.dateStrike)**")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                                .padding(.top, 1)
                            Text("Fasce garantite \(viewModel.guaranteed)")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)

                        if(viewModel.isStrikeToday) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.35))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(livePulse ? 2.8 : 1.0)
                                        .opacity(livePulse ? 0.0 : 1.0)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                                .frame(width: 16, height: 16)
                                .onAppear {
                                    livePulse = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                                            livePulse = true
                                        }
                                    }
                                }

                                Text("LIVE: ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)

                                MarqueeText(text: viewModel.strikeUpdateLive)
                                    .id(marqueeId)
                            }
                            
                            Divider()
                                .padding(.vertical, 2)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                            Text("Aderenti:")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            if viewModel.companiesStrikes.split(separator: ", ").count < 4 {
                                Text(viewModel.companiesStrikes)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        if viewModel.companiesStrikes.split(separator: ", ").count >= 4 {
                            Text(viewModel.companiesStrikes)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, closedStrike ? 0 : 12)
                    .background(Color(.secondarySystemBackground))
                    .frame(height: closedStrike ? 0 : nil, alignment: .top)
                    .opacity(closedStrike ? 0 : 1)
                    .clipped()
                }
                .onChange(of: closedStrike) { oldValue, newValue in
                    if !newValue {
                        marqueeId = UUID()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .red.opacity(0.12), radius: 8, x: 0, y: 3)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 10) {
                        ForEach(FilterBy.allCases) { filter in
                            Button(action: {
                                    withAnimation(.snappy){
                                        if(feedbacksEnabled){
                                            HapticManager.shared.trigger()
                                        }
                                        selectedFilter = filter
                                    }
                                }){
                                let nameIcon: String = getIconForFilter(for: filter.rawValue)
                                
                                if(nameIcon != ""){
                                    if(selectedFilter == .suggested) {
                                        if #available(iOS 18, *) {
                                            Label(filter.localizedTitle, systemImage: nameIcon)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .symbolEffect(.rotate, options: .nonRepeating, value: filter == .suggested ? suggestedTrigger : 0)
                                            .background(
                                                ZStack {
                                                    if selectedFilter == filter {
                                                        Capsule().fill(.red.gradient)
                                                    } else {
                                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                                    }
                                                }
                                            )
                                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        } else {
                                            Label(filter.localizedTitle, systemImage: nameIcon)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                ZStack {
                                                    if selectedFilter == filter {
                                                        Capsule().fill(.red.gradient)
                                                    } else {
                                                        Capsule().stroke(Color.secondary, lineWidth: 1)
                                                    }
                                                }
                                            )
                                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        }
                                    }
                                    else {
                                        Label(filter.localizedTitle, systemImage: nameIcon)
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
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                    }
                                }
                                else {
                                    Text(filter.localizedTitle)
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
                                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                }
                            }
                            .id(filter)
                        }
                    }
                    .padding(.horizontal)
                    .onAppear(){
                        if(selectedFilter != .suggested && selectedFilter != .all && selectedFilter != .bus) {
                            withAnimation {
                                proxy.scrollTo(selectedFilter, anchor: .center)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 16){
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12){
                            if viewModel.isLoading {
                                ForEach(0..<6, id: \.self) { _ in
                                    WorkRowSkeleton()
                                        .padding(.horizontal)
                                }
                            } else if let error = viewModel.errorMessage {
                                VStack (spacing: 10){
                                    Image(systemName: "wifi.exclamationmark")
                                        .font(.largeTitle)
                                    Text("Impossibile caricare i dati dal server.")
                                        .font(.title2)
                                    Text("Controlla la tua connessione e riprova.").font(.title3).foregroundColor(.gray)
                                    Button(action: {
                                        viewModel.fetchRequirements()
                                        viewModel.fetchVariables()
                                        viewModel.fetchWorks()
                                        viewModel.fetchMetroStatus()
                                        
                                        showMaintenanceMode = viewModel.maintenanceModeEnabled
                                    })
                                    {
                                        Label("Riprova", systemImage: "arrow.clockwise")
                                    }
                                    .buttonStyle(.bordered)
                                    if(showErrorMessages){
                                        Text("\(error)")
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .containerRelativeFrame(.vertical)
                                .padding()
                                .offset(y: -50)
                            } else {
                                let currentFilteredItems = filteredItems
                                VStack(spacing: 12) {
                                    if currentFilteredItems.isEmpty && searchInput.isEmpty {
                                        if selectedFilter == .suggested {
                                            Button {
                                                showInfoFavoriteLines = true
                                            } label: {
                                                Label("Come funziona?", systemImage: "questionmark.circle.fill")
                                                    .font(.footnote.weight(.semibold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.accentColor.opacity(0.15))
                                                    .foregroundStyle(Color.accentColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        VStack(spacing: 20) {
                                            Image(systemName: "rectangle.and.text.magnifyingglass")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.primary)
                                            VStack(spacing: 8) {
                                                Text("Nessun lavoro trovato per questo filtro")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.center)
                                                Text("Prova a modificare i filtri selezionati per trovare altri lavori.")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                            Button(action: {
                                                withAnimation(.snappy) {
                                                    if(feedbacksEnabled){
                                                        HapticManager.shared.trigger()
                                                    }
                                                    selectedFilter = .all
                                                }
                                            }) {
                                                Text("Mostra tutti i lavori")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.red)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.horizontal, 32)
                                        .padding(.bottom, 50)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .containerRelativeFrame(.vertical)
                                    }
                                    else if currentFilteredItems.isEmpty && !searchInput.isEmpty {
                                        VStack(spacing: 20) {
                                            Image(systemName: "exclamationmark.magnifyingglass")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.primary)
                                            VStack(spacing: 8) {
                                                Text("Nessun lavoro trovato per: \"\(searchInput)\"")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.center)
                                                Text("Prova a cercare qualcos'altro.")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                        }
                                        .padding(.horizontal, 32)
                                        .padding(.bottom, 50)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .containerRelativeFrame(.vertical)
                                    }
                                    else {
                                        if selectedFilter == .suggested {
                                            Button {
                                                showInfoFavoriteLines = true
                                            } label: {
                                                Label("Come funziona?", systemImage: "questionmark.circle.fill")
                                                    .font(.footnote.weight(.semibold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.accentColor.opacity(0.15))
                                                    .foregroundStyle(Color.accentColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        let itemsToShow = currentFilteredItems.filter { !$0.isFinishedMoreThanOneDayAgo }
                                        let itemsWithAds = itemsToShow.withAdsInserted(adCount: adMobManager.nativeAds.count)
                                        
                                        ForEach(itemsWithAds, id: \.index) { entry in
                                            if entry.type == .item, let item = entry.item {
                                                WorkInProgressRow(item: item)
                                                    .padding(.horizontal)
                                            } else if entry.type == .ad {
                                                if let adIndex = AdPositionCalculator(itemCount: itemsToShow.count, adCount: adMobManager.nativeAds.count).getAdIndexForPosition(entry.index),
                                                   adIndex < adMobManager.nativeAds.count {
                                                    NativeAdView(nativeAd: adMobManager.nativeAds[adIndex])
                                                        .frame(height: 160)
                                                        .padding(.horizontal)
                                                }
                                            }
                                        }
                                        .transaction { $0.animation = nil }
                                        .padding(.top, 5)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        }
                        .id("top")
                        .onChange(of: selectedFilter) { _, _ in
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                        .onChange(of: searchInput) { _, _ in
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
            .onAppear(){
                if(!alreadyRefreshed) {
                    viewModel.fetchWorks()
                    viewModel.fetchVariables()
                    viewModel.fetchMetroStatus()
                    viewModel.fetchRequirements {
                        showMaintenanceMode = viewModel.maintenanceModeEnabled
                    }
                    alreadyRefreshed = true
                }
                
                if viewModel.strikeEnabled && showStrikeBanner && !closedStrike {
                    marqueeId = UUID()
                }
                
                if !hasNotCompletedSetup {
                    consentManager.requestConsentInfoUpdate()
                }
                
                if consentManager.isReady && !adsRequested {
                    if let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
                        adsRequested = true
                        adMobManager.loadNativeAds(adUnitID: adUnitID)
                    }
                }
            }
            .onChange(of: hasNotCompletedSetup) { _, completed in
                if !completed {
                    consentManager.requestConsentInfoUpdate()
                }
            }
            .onChange(of: consentManager.isReady) { _, ready in
                if ready && !adsRequested, let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
                    adsRequested = true
                    adMobManager.loadNativeAds(adUnitID: adUnitID)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTrainFilter)) { notification in
                selectedFilter = .train
            }
            .refreshable {
                viewModel.fetchWorks()
                viewModel.fetchVariables()
                viewModel.fetchMetroStatus()
                viewModel.fetchRequirements {
                    showMaintenanceMode = viewModel.maintenanceModeEnabled
                }
            }
            .fullScreenCover(isPresented: $showMaintenanceMode) {
                MaintenanceView(maintenanceDeps: viewModel.maintenanceDeps, maintenanceDepsEn: viewModel.maintenanceDepsEn) {
                    showMaintenanceMode = false
                }
            }
            .fullScreenCover(isPresented: $showWrapped, onDismiss: {
                hasOpenedWrapped = true
                showWrappedOpenedInfo = true
            }) {
                WrappedView()
            }
            .alert("Riguarda il Wrapped", isPresented: $showWrappedOpenedInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("D'ora in poi, troverai il Wrapped sotto la sezione \"Account\" nelle impostazioni.")
            }
            .onChange(of: selectedFilter) { oldValue, newValue in
                if newValue == .suggested && feedbacksEnabled {
                    suggestedTrigger += 1 ///TRIGGERS THE HAPTICS
                    playRotateHaptics()
                }
            }
            .sheet(isPresented: $showInfoFavoriteLines) {
                DetailSetYourLineView(showInfoView: $showInfoFavoriteLines)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openLetueLinkInfo)) { _ in
                selectedFilter = .suggested
                showInfoFavoriteLines = true
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func playRotateHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        let pulses: [(delay: TimeInterval, intensity: CGFloat)] = [
            (0.00, 0.2),
            (0.10, 0.5),
            (0.20, 0.8),
            (0.30, 1.0),
            (0.40, 0.7),
            (0.50, 0.4),
            (0.58, 0.15)
        ]

        for pulse in pulses {
            DispatchQueue.main.asyncAfter(deadline: .now() + pulse.delay) {
                generator.impactOccurred(intensity: pulse.intensity)
            }
        }
    }
}

struct MainHeaderView: View {
    @ObservedObject var viewModel: WorkViewModel
    @Binding var showMaintenanceMode: Bool

    var body: some View {
        HStack {
            Text("Lavori in corso")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Button(action: refresh) {
                refreshIcon
            }
        }
        .padding(.horizontal)
        .padding(.top, 57)
        .padding(.bottom, 5)
    }

    @ViewBuilder
    private var refreshIcon: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.0)
                .tint(.red)
        } else {
            Image(systemName: "arrow.clockwise")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }

    private func refresh() {
        viewModel.isLoading = true
        viewModel.fetchWorks()
        viewModel.fetchVariables()
        viewModel.fetchMetroStatus()
        viewModel.fetchRequirements {
            showMaintenanceMode = viewModel.maintenanceModeEnabled
        }
    }
}

private struct MarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct MarqueeText: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isReady: Bool = false
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.system(size: 13))
                .fixedSize()
                .hidden()
                .background(
                    GeometryReader { tg in
                        Color.clear.preference(
                            key: MarqueeTextWidthKey.self,
                            value: tg.size.width
                        )
                    }
                )
            
            if isReady {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(height: geo.size.height, alignment: .center)
                    .offset(x: offset)
            }
        }
        .frame(height: 18)
        .clipped()
        .onPreferenceChange(MarqueeTextWidthKey.self) { tw in
            textWidth = tw
            if containerWidth > 0 && tw > 0 && !isReady {
                isReady = true
                startMarquee()
            }
        }
        .background(
            GeometryReader { cg in
                Color.clear
                    .onAppear {
                        containerWidth = cg.size.width
                        if textWidth > 0 && containerWidth > 0 && !isReady {
                            isReady = true
                            startMarquee()
                        }
                    }
                    .onChange(of: cg.size.width) { _, cw in
                        containerWidth = cw
                        if textWidth > 0 && cw > 0 && !isReady {
                            isReady = true
                            startMarquee()
                        }
                    }
            }
        )
        .onDisappear {
            isAnimating = false
        }
        .onAppear {
            if isReady && !isAnimating {
                startMarquee()
            }
        }
    }

    private func startMarquee() {
        guard !isAnimating, textWidth > 0, containerWidth > 0 else { return }
        isAnimating = true
        animateMarquee()
    }

    private func animateMarquee() {
        guard isAnimating else { return }
        offset = containerWidth
        let totalWidth = containerWidth + textWidth
        let duration = Double(totalWidth) / 55.0
        
        withAnimation(.linear(duration: duration)) {
            offset = -textWidth
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard isAnimating else { return }
            animateMarquee()
        }
    }
}

struct WorkInProgressRow: View {
    let item: WorkItem
    
    @State private var isExpanded = false
    @State private var showTranslation = false
    @State private var aiSummary: String = ""
    @State private var isAiSummaryLoading: Bool = false
    
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    
    private let italianLoc = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "it_IT"))
    private var isImportant: Bool {item.details.contains("[LAVORO IMPORTANTE]")}
    private var cleanedDetails: String {
        item.details
            .replacingOccurrences(of: "[LAVORO IMPORTANTE]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var shouldShowTranslationButton: Bool {Locale.current.language.languageCode?.identifier != "it" || showTranslateButton == true}
    var textToTranslate: String {"\(item.title)\n\n\(cleanedDetails)\n\nStrade: \(item.roads)\n\nLinee coinvolte: \(item.lines.joined(separator: ", "))"}

    var body: some View {
        VStack(spacing: 0) {
            if isImportant {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("LAVORO IMPORTANTE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.red)
            }
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(cleanedDetails)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        if shouldShowTranslationButton {
                            Button {
                                showTranslation = true
                            } label: {
                                Label("Traduci", systemImage: "translate")
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }

                        if #available(iOS 26, *) {
                            AISummarizeButton(
                                text: cleanedDetails,
                                summary: $aiSummary,
                                isLoading: $isAiSummaryLoading
                            )
                        }
                    }
                    
                    if isAiSummaryLoading {
                        AISummarySkeletonView()
                    } else if !aiSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Riepilogo AI", systemImage: "text.line.3.summary")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(aiSummary)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(Color.accentColor.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    if item.titleIcon == "point.bottomleft.forward.to.arrow.triangle.uturn.scurvepath" {
                        if #available(iOS 18, *) {
                            Label(item.title, systemImage: item.titleIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Label(item.title, systemImage: "arrow.up.forward.app.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }
                    else if item.titleIcon == "arrow.trianglehead.2.counterclockwise" {
                        if #available(iOS 18, *) {
                            Label(item.title, systemImage: item.titleIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Label(item.title, systemImage: "shuffle")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }
                    else {
                        Label(item.title, systemImage: item.titleIcon)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color("TextColor"))
                    }
                    Label(item.roads, systemImage: "mappin")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color("TextColor"))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.lines, id: \.self) { line in
                                if line.contains("Filobus") {
                                    Label(line.replacing("Filobus", with: String(localized: .filobus)), systemImage: "bolt.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                } else if line.starts(with: "N") {
                                    Label(line, systemImage: "moon.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                } else {
                                    Text(line)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                }
                            }
                        }
                    }
                    VStack(spacing: 6) {
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .tint(item.progress == 1.0 ? .green : .red)

                        HStack {
                            Text(item.startDate.formatted(self.italianLoc))
                                .font(.caption)
                                .foregroundStyle(Color("TextColor"))
                            Spacer()
                                .frame(height: 8)
                            Text(item.endDate.formatted(self.italianLoc))
                                .font(.caption)
                                .foregroundStyle(Color("TextColor"))
                        }
                        Spacer().frame(height: 8)
                        Text(item.company)
                            .foregroundStyle(Color("TextColor"))
                            .padding(.top, 4)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isImportant ? Color.red.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: isImportant ? .red.opacity(0.30) : .black.opacity(0.06),
            radius: isImportant ? 14 : 6,
            x: 0,
            y: isImportant ? 4 : 3
        )
        .translationPresentation(isPresented: $showTranslation, text: textToTranslate)
    }
}

struct AISummarySkeletonView: View {
    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: -0.6, y: -0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Riepilogo AI", systemImage: "text.line.3.summary")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                    .frame(maxWidth: 160)
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(.systemGray3), Color(.systemGray2), Color(.systemGray3)],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 4)
        .onAppear {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                startPoint = .init(x: 1.2, y: 1.2)
                endPoint = .init(x: 2.4, y: 2.2)
            }
        }
    }
}

@available(iOS 26, *)
struct AISummarizeButton: View {
    let text: String
    @Binding var summary: String
    @Binding var isLoading: Bool

    private var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var body: some View {
        if isAvailable {
            Button {
                Task { await summarize() }
            } label: {
                Label(
                    isLoading ? "Riassumo..." : "Riassumi",
                    systemImage: "text.line.3.summary"
                )
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.12))
                .foregroundStyle(.red.gradient)
                .clipShape(Capsule())
            }
            .disabled(isLoading)
        }
    }

    private func summarize() async {
        isLoading = true
        summary = ""
        defer { isLoading = false }

        let session = LanguageModelSession {
            String(localized: .inputAI)
        }

        do {
            let stream = session.streamResponse(to: text)
            for try await partial in stream {
                summary = partial.content
            }
        } catch {
            summary = String(localized: .aiError)
        }
    }
}

struct ShimmerModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0.0

    var duration: Double = 1.25
    var angle: Angle = .degrees(12)
    var bandFraction: CGFloat = 0.35
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let bandWidth = max(80, width * bandFraction)
                    let startX = -bandWidth
                    let endX = width + bandWidth
                    let x = startX + (endX - startX) * progress

                    let highlight = colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.22)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: highlight, location: 0.5),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: bandWidth, height: height * 2)
                        .rotationEffect(angle)
                        .offset(x: x, y: 0)
                        .blendMode(.screen)
                }
                .allowsHitTesting(false)
                .clipped()
            }
            .onAppear {
                guard !reduceMotion else { return }
                progress = 0
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    progress = 1
                }
            }
            .onDisappear {
                progress = 0
            }
    }
}

extension View {func shimmer() -> some View { modifier(ShimmerModifier()) }}

struct WorkRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 180, height: 14)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 40, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 32, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 50, height: 20)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 28, height: 20)
                }

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 6)
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 10)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 10)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 120, height: 12)
                    .frame(alignment: .center)
            }
            .shimmer()
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

//MARK: SETTINGS VIEW
struct SettingsView: View{
    @State private var expandedTrenord = false
    @State private var expandedATM = false
    @State private var expandedATMLines = false
    @State private var presentedAlertReset = false
    @State private var showBuildNumber = false
    @State private var selectedURL: URL?
    @State private var showErrorDBSavePopUp = false
    @State private var showInfoMapDeviations: Bool = false
    @State private var showWrapped: Bool = false
    @AppStorage("hasOpenedWrapped") private var hasOpenedWrapped: Bool = false
    @StateObject var viewModel: WorkViewModel
    @StateObject var authManager = AuthManager()
    
    ///APP DATAS
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("preferredFilter") private var preferredFilter: FilterBy = .all
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @AppStorage("recentlySearchedLinesData") private var recentlySearchedLinesData: Data = Data()
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink(destination: AccountView(auth: authManager)) {
                        HStack(spacing: 12) {
                            if authManager.isLoggedIn() {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 44, height: 44)
                                    
                                    Text(authManager.getInitialIconName())
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundStyle(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if authManager.isLoggedIn() {
                                    Text(authManager.getFullName())
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Il tuo Account")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Text("Gestisci il tuo Account")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    if(viewModel.wrappedEnabled && hasOpenedWrapped) {
                        Button(action: {
                            if feedbacksEnabled { HapticManager.shared.trigger() }
                            showWrapped = true
                        }) {
                            HStack(spacing: 8) {
                                Image("iconAppAndroid")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))

                                Text("RIGUARDA IL WRAPPED DEL MESE")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .tracking(0.5)

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(Color(red: 224/255, green: 32/255, blue: 34/255))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 10)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                Section(content: {
                    DisclosureGroup(isExpanded: $expandedTrenord){
                        HStack{
                            Label {
                                Text("Linee Suburbane")
                            } icon: {
                                Image("sLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                
                                if linesFavorites.contains("S") {
                                    linesFavorites.removeAll { $0 == "S" }
                                } else {
                                    linesFavorites.append("S")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
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
                                Text("Linee Regionali")
                            } icon: {
                                Image("rLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("R") {
                                    linesFavorites.removeAll { $0 == "R" }
                                } else {
                                    linesFavorites.append("R")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
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
                                Text("Linee Regio Express")
                            } icon: {
                                Image("reLinesIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("TextColor"))
                                    .tint(Color("TextColor"))
                            }
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("RE") {
                                    linesFavorites.removeAll { $0 == "RE" }
                                } else {
                                    linesFavorites.append("RE")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
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
                    .onChange(of: expandedTrenord) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    DisclosureGroup(isExpanded: $expandedATM){
                        HStack{
                            Label("Linee Metropolitane", systemImage: "tram.fill.tunnel")
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Metro") {
                                    linesFavorites.removeAll { $0 == "Metro" }
                                } else {
                                    linesFavorites.append("Metro")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
                                }
                            }) {
                                Image(systemName: linesFavorites.contains("Metro") ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(linesFavorites.contains("Metro") ? .orange : .gray)
                            }
                            .buttonStyle(.borderless)
                        }
                        HStack{
                            Label("Linee Tram", systemImage: "tram.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Tram") {
                                    linesFavorites.removeAll { $0 == "Tram" }
                                } else {
                                    linesFavorites.append("Tram")
                                }
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
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
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                if(feedbacksEnabled){
                                    HapticManager.shared.trigger()
                                }
                                
                                if linesFavorites.contains("Bus") {
                                    linesFavorites.removeAll { $0 == "Bus" }
                                } else {
                                    linesFavorites.append("Bus")
                                }
                                
                                NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                                
                                Task {
                                    let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                    
                                    if(preferences.enable_favorites) {
                                        let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                        showErrorDBSavePopUp = !res
                                    }
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
                    .onChange(of: expandedATM) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    HStack{
                        Label("Linee TILO", systemImage: "train.side.front.car")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("Tilo") {
                                linesFavorites.removeAll { $0 == "Tilo" }
                            } else {
                                linesFavorites.append("Tilo")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("Tilo") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("Tilo") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee Movibus", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z6") {
                                linesFavorites.removeAll { $0 == "z6" }
                            } else {
                                linesFavorites.append("z6")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z6") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z6") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee STAV", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z55") {
                                linesFavorites.removeAll { $0 == "z55" }
                            } else {
                                linesFavorites.append("z55")
                            }
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z55") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z55") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee STAR", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("z50") {
                                linesFavorites.removeAll { $0 == "z50" }
                            } else {
                                linesFavorites.append("z50")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("z50") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("z50") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    HStack{
                        Label("Linee Autoguidovie", systemImage: "bus.fill")
                        Spacer()
                        Button(action: {
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                            
                            if linesFavorites.contains("Autoguidovie") {
                                linesFavorites.removeAll { $0 == "Autoguidovie" }
                            } else {
                                linesFavorites.append("Autoguidovie")
                            }
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                            
                            Task {
                                let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                                
                                if(preferences.enable_favorites) {
                                    let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                    showErrorDBSavePopUp = !res
                                }
                            }
                        }) {
                            Image(systemName: linesFavorites.contains("Autoguidovie") ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(linesFavorites.contains("Autoguidovie") ? .orange : .gray)
                        }
                        .buttonStyle(.borderless)
                    }
                }, header: {
                    FavoritesHeader()
                })
                Section("Generali"){
                    NavigationLink(destination: NotificationsView(viewModel: viewModel)){
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    Picker(selection: $preferredFilter){
                        ForEach(FilterBy.allCases) { filter in
                            Text(filter.localizedTitle).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    } label: {
                        Label("Filtro Predefinito", systemImage: "line.3.horizontal.decrease")
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: preferredFilter) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                    }
                    NavigationLink(destination: AppearancePickerView()) {
                        HStack {
                            Label("Aspetto e Lingua", systemImage: "circle.righthalf.filled")
                        }
                    }
                    NavigationLink(destination: AdvancedOptionsView()){
                        Label("Opzioni Avanzate", systemImage: "gearshape.fill")
                    }
                }
                Section("Aiuto"){
                    NavigationLink(destination: InfoView()){
                        Label("Fonti & Sviluppo", systemImage: "person.crop.circle.badge.questionmark")
                    }
                    NavigationLink(destination: HowAppWorksView()){
                        Label("Funzioni dell'App", systemImage: "questionmark.circle.fill")
                    }
                    HStack{
                        Button(action: {
                            showBuildNumber = !showBuildNumber
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }){
                            Label {
                                Text("Versione")
                                    .foregroundColor(Color("TextColor"))
                            } icon: {
                                Image(systemName: "info.circle.fill")
                            }
                        }
                        Spacer()
                        if(showBuildNumber){Text("\(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                            .textSelection(.enabled)}
                        else{Text("\(Bundle.main.shortVersion)")
                            .textSelection(.enabled)}
                    }
                }
                Section("Collegamenti") {
                    ShareLink(item: URL(string: "https://apps.apple.com/us/app/lavorami/id6760344298")!) {
                        Label("Condividi LavoraMi", systemImage: "arrowshape.turn.up.right.fill")
                    }
                    Button(action: {
                        Task {@MainActor in
                            requestReview()
                            if(feedbacksEnabled){
                                HapticManager.shared.trigger()
                            }
                        }
                    }){
                        Label {
                            Text("Valuta LavoraMi")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "star.fill")
                        }
                    }
                    Button(action: {
                        showInfoMapDeviations = true
                    }){
                        Label {
                            Text("Info sulle Mappe")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "location.fill")
                        }
                    }
                }
                Section(footer: Text("Le impostazioni vengono salvate automaticamente.")) {
                    Button(role: .destructive) {
                        if(feedbacksEnabled){
                            HapticManager.shared.trigger()
                        }
                        presentedAlertReset = true
                    } label: {
                        Label("Ripristina Impostazioni", systemImage: "arrow.counterclockwise")
                    }
                }
                Section() {} footer: {
                    HStack(spacing: 30) {
                            Spacer()
                            Link(destination: URL(string: "https://www.instagram.com/lavoramiapp/")!) {
                                Image("instagram")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            Link(destination: URL(string: "https://www.tiktok.com/@lavoramiapp")!) {
                                Image("tiktok")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            
                            Button {
                                let url = URL(string: "https://www.lavorami.it\((colorScheme == .dark) ? "?theme=dark" : "?theme=light")")!
                                
                                if(howToOpenLinks == .inApp) {
                                    selectedURL = url
                                }
                                else {
                                    openURLAction(url)
                                }
                            } label: {
                                Image(systemName: "network")
                                    .font(.system(size: 20))
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Impostazioni")
            .alert("Sei sicuro?", isPresented: $presentedAlertReset) {
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) {
                    enableNotifications = true
                    preferredFilter = .all
                    linesFavorites = []
                    linesSelected = []
                    showErrorMessages = false
                    showStrikeBanner = true
                    requireFaceID = true
                    howToOpenLinks = .inApp
                    appearanceSelection = .system
                    feedbacksEnabled = true
                    showTranslateButton = false
                    showRecentSearches = true
                    recentlySearchedLinesData = Data()
                }
            } message: {
                Text("Sei sicuro di voler ripristinare le impostazioni?")
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio delle linee preferite. Controlla la tua connessione ad Internet.")
            }
            .sheet(isPresented: $showInfoMapDeviations) {
                LineDeviationInfoView()
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .fullScreenCover(isPresented: $showWrapped, onDismiss: {
                hasOpenedWrapped = true
            }) {
                WrappedView()
            }
        }
    }
}

struct FavoritesHeader: View {
    @State private var showInfo = false
    
    var body: some View {
        HStack {
            Text("Preferiti")
            Button(action: { showInfo.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.borderless)
            .alert("Scegli i tuoi interessi", isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Scegli i tuoi operatori di trasporti più usati e, mettendoli nei preferiti, riceverai subito le notifiche con nuovi lavori.")
            }
            .textCase(nil)
        }
    }
}

struct AppearancePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURLAction
    @AppStorage("appearanceSelection") private var appearanceSelection: AppearanceType = .system

    var body: some View {
        List {
            Section("Tema") {
                ForEach(AppearanceType.allCases) { filter in
                    Button {
                        appearanceSelection = filter
                        dismiss()
                    } label: {
                        HStack {
                            Label {
                                Text(filter.description)
                            } icon: {
                                Image(systemName: filter.iconName)
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            if appearanceSelection == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(Color("TextColor"))
                }
            }
            Section() {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇮🇹 Italiano")
                        if(Locale.current.language.languageCode?.identifier == "it") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇬🇧 Inglese")
                        if(Locale.current.language.languageCode?.identifier == "en") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURLAction(url)
                    }
                } label: {
                    HStack {
                        Text("🇪🇸 Spagnolo")
                        if(Locale.current.language.languageCode?.identifier == "es") {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .foregroundColor(Color("TextColor"))
            } header: {
                Text("Lingua")
            } footer: {
                Text("Per modificare la lingua, sarai reindirizzato alle impostazioni dell'app su iOS.")
            }
        }
        .navigationTitle("Aspetto e Lingua")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountView: View {
    @StateObject var auth: AuthManager
    @State private var email: String = ""
    @State private var emailRecoverPassword: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var tabTitle: String = ""
    @State private var isLogginIn: Bool = true
    @State private var loggedIn: Bool = false
    @State private var resettingPassword: Bool = false
    @State private var passwordResetted: Bool = false
    @State private var popUpVerifyMail: Bool = false
    @State private var showError: Bool = false
    @State private var showDeletePopUp: Bool = false
    @State private var showDataManagementPopUp: Bool = false
    @State private var showEditPasswordPopUp: Bool = false
    @State private var showErrorDBSavePopUp: Bool = false
    @State private var showConfirmToExitPopUp: Bool = false
    @State private var isLocked: Bool = true
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var isBiometricAuthCompleted: Bool = false
    @State private var showMailApple: Bool = false
    @State private var logginIn: Bool = false
    @State var isRequiringData: Bool = false
    @State var saveFavoritesData = true
    @State var saveYourLinesData = true
    @State private var currentNonce: String?
    @State private var currentSyncStatus: String = String(localized: .sincronizzazione)
    @State private var currentSyncStatusIcon: String = "cloudSyncing"
    @State private var showPopUpNotSynched: Bool = false
    @State private var newUsername: String = ""
    @State private var showChangeUsernamePopUp: Bool = false
    @State private var showAddUsernamePopUp: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("emailSaved") var emailSaved: String = ""
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if isLogginIn && !loggedIn && !resettingPassword {loginSection}
                    if !isLogginIn && !loggedIn && !resettingPassword {signUpSection}
                    if loggedIn && !resettingPassword {loggedInSection}
                    if resettingPassword {resetPasswordSection}
                }
                .padding(25)
            }
            .blur(radius: isLocked ? 12 : 0)
            .animation(.easeInOut(duration: 0.25), value: isLocked)
            .allowsHitTesting(!isLocked)
            .onAppear(perform: handleOnAppear)
            .alert("Sei sicuro?", isPresented: $showConfirmToExitPopUp) {
                Button("Annulla", role: .cancel) { }
                Button("Conferma", role: .destructive, action: performSignOut)
            } message: {
                Text("Sei sicuro di voler uscire dall'account?")
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio delle linee preferite. Riprova più tardi.")
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $showDataManagementPopUp) {
                AccountDatasInfoView(authManager: auth, saveFavoritesData: saveFavoritesData, saveYourLinesData: saveYourLinesData, currentSyncStatus: $currentSyncStatus, currentSyncStatusIcon: $currentSyncStatusIcon)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var loginSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bentornato")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Accedi al tuo Account per continuare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)

            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.gray)
                    SecureField("Password", text: $password)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack {
                    Spacer()
                    Button("Password dimenticata?") {
                        resettingPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    
                    Button(action: { isLogginIn = false }) {
                        Text("Non hai un account?")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let err = auth.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            termsAndPrivacyView
            appleSignInLoginButton
            loginButton
        }
    }
    
    private var signUpSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Crea account")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Registrati per iniziare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)

            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "at")
                        .foregroundStyle(.gray)
                    TextField("Nome utente", text: $fullName)
                        .textInputAutocapitalization(.words)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 15) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.gray)
                    SecureField("Password", text: $password)
                        .disabled(auth.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                HStack{
                    Spacer()
                    Button(action: { isLogginIn = true }) {
                        Text("Hai già un account?")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let err = auth.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            termsAndPrivacyView
            appleSignInSignUpButton
            signUpButton
        }
    }
    
    private var loggedInSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                Text("👋 Ciao \(fullName)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Qui puoi gestire il tuo Account e le tue informazioni.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.top, -8)
                
                Section("Informazioni") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "at")
                                .foregroundStyle(.red)
                                .font(.system(size: 25))
                            
                            Text(fullName)
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 25))
                            
                            Button(action: {
                                showChangeUsernamePopUp = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if email.contains("privaterelay") {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill.viewfinder")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 25))
                                
                                Text("ID: \(email.prefix(while: {$0 != "@"}))")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 25))
                                
                                Text(email)
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Image(currentSyncStatusIcon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundStyle(.red)
                            
                            if(currentSyncStatus.contains(String(localized: .sincronizzazione))){
                                ProgressView()
                                    .foregroundStyle(.red)
                            }
                            
                            Text(currentSyncStatus)
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 25))
                            
                            if(currentSyncStatus.contains(String(localized: .nonSincronizzato))) {
                                Button(action: {
                                    showPopUpNotSynched = true
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if(currentSyncStatus.contains(String(localized: .erroreSincronizzato))) {
                                Button(action: {
                                    currentSyncStatus = String(localized: .sincronizzazione)
                                    currentSyncStatusIcon = "cloudSyncing"
                                    handleOnAppear()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        if auth.isLoggedInWithApple() {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(Color("TextColor"))
                                    .font(.system(size: 25))
                                
                                Text("Account creato con Apple")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                            }
                        }
                    }
                }
                .foregroundStyle(.gray)
                
                manageSection
                .sheet(isPresented: $showChangeUsernamePopUp) {
                    ChangeUsernameView(auth: auth, fullName: $fullName)
                }
                .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive, action: performAccountDeletion)
                } message: {
                    Text("Sei sicuro di voler Eliminare Definitivamente il tuo Account?")
                }
                .alert("Modifica Password", isPresented: $showEditPasswordPopUp) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive) {
                        Task { await auth.requestPasswordReset(email: email) }
                    }
                } message: {
                    Text("Ti invieremo una mail per modificare la tua password, vuoi continuare?")
                }
                .foregroundStyle(.gray)
                .alert("Dati non Sincronizzati", isPresented: $showPopUpNotSynched) {
                    Button("Chiudi", role: .cancel) { }
                } message: {
                    Text("Hai scelto di non sincronizzare i dati del tuo Account attraverso la funzione \"Preferenze Dati\". Per sincronizzarli, attiva almeno una delle opzioni disponibili.")
                }
                .alert("Inserisci Nome Utente", isPresented: $showAddUsernamePopUp) {
                    TextField("Nome utente", text: $newUsername)
                    Button("Continua") {
                        Task {
                            do {
                                if(!newUsername.isEmpty) {
                                    try await auth.updateUserName(newUserName: newUsername)
                                    fullName = newUsername
                                    newUsername = ""
                                    showChangeUsernamePopUp = false
                                }
                            }
                            catch {}
                        }
                    }
                    .disabled(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } message: {
                    Text("Il tuo Account non ha un nome utente, inseriscine uno.")
                }
                
                Spacer()

                Button(role: .destructive, action: { showConfirmToExitPopUp = true }) {
                    Label("Esci", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
            }
            .onAppear(perform: populateUserData)
        }
    }
    
    private var manageSection: some View {
        Section("Gestisci") {
            VStack(spacing: 8) {
                if !auth.isLoggedInWithApple() {
                    Button(role: .destructive, action: { showEditPasswordPopUp = true }) {
                        Label("Modifica Password", systemImage: "lock.fill")
                            .font(.system(size: 15))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5, y: 3)
                    }
                }
                Button(role: .destructive, action: { showDeletePopUp = true }) {
                    Label("Elimina Account", systemImage: "trash.fill")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
                
                Button(role: .destructive, action: { showDataManagementPopUp = true }) {
                    Label {
                        Text("Preferenze Dati")
                    } icon: {
                        Image("cloudManage")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5, y: 3)
                }
                
                NavigationLink(destination: RequestDataDownload(isRequiringData: $isRequiringData)) {
                    Label("Richiedi i tuoi dati", systemImage: "person.and.background.dotted")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5, y: 3)
                }
            }
        }
    }
    
    private var resetPasswordSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset Password")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Recupera qui la Password del tuo Account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)
            
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.gray)
                    TextField("Email", text: $emailRecoverPassword)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack{
                Spacer()
                Button(action: {
                    isLogginIn = true
                    resettingPassword = false
                    passwordResetted = false
                }){
                    Text("Torna al Login")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.top, -10)
            
            Spacer()
            
            Button(role: .destructive, action: performPasswordResetRequest) {
                Label("Invia Email", systemImage: "paperplane.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((!validateEmail(emailRecoverPassword)) ? Color.gray.opacity(0.5) : Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5, y: 3)
            }
            .disabled(!validateEmail(emailRecoverPassword))
            .alert("Email inviata!", isPresented: $passwordResetted) {
                Button("Chiudi", role: .cancel) {
                    resettingPassword = false
                    passwordResetted = false
                }
            } message: {
                Text("Email inviata a \(emailRecoverPassword)!")
            }
        }
    }
    
    private var termsAndPrivacyView: some View {
        HStack(spacing: 0) {
            Text("Continuando, accetti i ")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                let url = URL(string: "https://www.lavorami.it/termsofservice\((colorScheme == .dark) ? "" : "?theme=light")")!
                if howToOpenLinks == .inApp {
                    selectedURL = url
                } else {
                    openURLAction(url)
                }
            } label: {
                Text("Termini")
                    .font(.subheadline)
            }
            
            Text(" e la ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                let url = URL(string: "https://www.lavorami.it/privacypolicy\((colorScheme == .dark) ? "" : "?theme=light")")!
                if howToOpenLinks == .inApp {
                    selectedURL = url
                } else {
                    openURLAction(url)
                }
            } label: {
                Text("Privacy Policy.")
                    .font(.subheadline)
            }
        }
    }
    
    private var appleSignInLoginButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleAppleSignInCompletion(result: result)
        }
        .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
        .frame(height: 50)
        .cornerRadius(16)
    }
    
    private var appleSignInSignUpButton: some View {
        SignInWithAppleButton(.signUp) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleAppleSignInCompletion(result: result)
        }
        .signInWithAppleButtonStyle((colorScheme == .dark) ? .whiteOutline : .black)
        .frame(height: 50)
        .cornerRadius(16)
    }
    
    private var loginButton: some View {
        Button(action: performLogin) {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Label(auth.isLoading ? "Accedo..." : "Accedi", systemImage: "arrow.up.forward.app.fill")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background((!validateUserInputs(email: email, password: password) || logginIn) ? Color.gray.opacity(0.5) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 5, y: 3)
        }
        .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading || logginIn)
    }
    
    private var signUpButton: some View {
        Button(action: performSignUp) {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Label(auth.isLoading ? "Registrazione..." : "Registrati", systemImage: "rectangle.portrait.and.arrow.right.fill")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background((!validateUserInputs(email: email, password: password) || isLogginIn) ? Color.gray.opacity(0.5) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 5, y: 3)
        }
        .disabled(!validateUserInputs(email: email, password: password) || auth.isLoading)
        .alert("Conferma Mail", isPresented: $popUpVerifyMail) {
            Button("Chiudi", role: .cancel) {
                popUpVerifyMail = false
                isLogginIn = true
            }
        } message: {
            Text("Verifica il tuo indirizzo Email con la mail che ti abbiamo inviato per continuare.")
        }
    }
    
    private func handleOnAppear() {
        loggedIn = auth.isLoggedIn()
        if loggedIn {
            if fullName.isEmpty { fullName = auth.getFullName() }
            if email.isEmpty, let sess = auth.session {email = sess.user.email ?? email}
            
            Task {
                do {
                    let res: UserPreferencesDatas = try await auth.fetchUserPreferencesAccount()
                    
                    if res.enable_favorites {
                        currentSyncStatus = String(localized: .sincronizzato)
                        currentSyncStatusIcon = "cloudSynced"
                        linesFavorites = try await auth.fetchUserFavorites()
                    } else {
                        currentSyncStatus = String(localized: .erroreSincronizzato)
                        currentSyncStatusIcon = "cloudFailSync"
                    }
                    
                    if res.enable_your_lines {
                        linesSelected = try await auth.fetchUserLines()
                    }
                    
                    if(!res.enable_favorites && !res.enable_your_lines){
                        currentSyncStatus = String(localized: .nonSincronizzato)
                        currentSyncStatusIcon = "cloudDisabled"
                    }
                    
                } catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
            }
            
            tabTitle = "Account"
        }
        if requireFaceID && loggedIn && !isRequiringData && !isBiometricAuthCompleted {
            BiometricAuth.authenticate {
                isLocked = false
            } onFailure: { error in
                dismiss()
            }
            isBiometricAuthCompleted = true
        } else {
            isLocked = false
            isRequiringData = false
            isBiometricAuthCompleted = true
        }
    }
    
    private func populateUserData() {
        if fullName.isEmpty { fullName = auth.getFullName() }
        if email.isEmpty, let sess = auth.session {
            email = sess.user.email ?? email
            Task {
                do {
                    linesFavorites = try await auth.fetchUserFavorites()
                    linesSelected = try await auth.fetchUserLines()
                    try await auth.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                    
                    currentSyncStatus = String(localized: .sincronizzato)
                    currentSyncStatusIcon = "cloudSynced"
                }
                catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
            }
        }
        
        if(auth.getFullName().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.getFullName().contains("User")){showAddUsernamePopUp = true}
        
        emailSaved = email
    }
    
    private func performLogin() {
        logginIn = true
        Task {
            await auth.signIn(email: email, password: password)
            
            if auth.isLoggedIn() {
                if fullName.isEmpty { fullName = auth.getFullName() }
                if email.isEmpty, let sess = auth.session { email = sess.user.email ?? email }
                
                do {
                    linesFavorites = try await auth.fetchUserFavorites()
                    linesSelected = try await auth.fetchUserLines()
                    currentSyncStatus = String(localized: .sincronizzato)
                    currentSyncStatusIcon = "cloudSynced"
                }
                catch {
                    currentSyncStatus = String(localized: .erroreSincronizzato)
                    currentSyncStatusIcon = "cloudFailSync"
                }
                
                self.loggedIn = true
            }
            
            tabTitle = "Account"
            logginIn = false
        }
    }
    
    private func performSignUp() {
        logginIn = true
        Task {
            await auth.signUp(email: email, password: password, name: fullName)
            popUpVerifyMail = auth.errorMessage == nil
            logginIn = false
            tabTitle = "Account"
        }
    }
    
    private func performSignOut() {
        Task {
            loggedIn = false
            isLogginIn = true
            email = ""
            password = ""
            fullName = ""
            tabTitle = ""
            await auth.signOut()
        }
    }
    
    private func performAccountDeletion() {
        Task {
            email = ""
            password = ""
            fullName = ""
            loggedIn = false
            isLogginIn = true
            await auth.deleteAccount()
        }
    }
    
    private func performPasswordResetRequest() {
        Task {
            await auth.requestPasswordReset(email: emailRecoverPassword)
            passwordResetted = true
        }
    }
    
    private func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) {
        Task {
            logginIn = true
            switch result {
            case .failure(let error):
                print("Apple Sign In error: \(error)")
                logginIn = false
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let idTokenData = credential.identityToken,
                      let idToken = String(data: idTokenData, encoding: .utf8),
                      let nonce = currentNonce
                else {
                    logginIn = false
                    return
                }
                
                var newNameFromApple: String? = nil
                if let personName = credential.fullName {
                    let given = personName.givenName ?? ""
                    let family = personName.familyName ?? ""
                    let composed = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
                    if !composed.isEmpty {
                        newNameFromApple = composed
                    }
                }
                
                await auth.signInWithApple(nonce: nonce, idToken: idToken, fullName: newNameFromApple)
                fullName = auth.getFullName()
                loggedIn = auth.isLoggedIn()
                logginIn = false
                tabTitle = "Account"
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validateUserInputs(email: String, password: String) -> Bool {
        return password.count >= 8 && validateEmail(email)
    }
}

struct ChangeUsernameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @StateObject var auth: AuthManager
    
    @State var newUsername: String = ""
    @State var isLoading: Bool = true
    @State var focused: Bool = false
    @Binding var fullName: String
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "at")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.red)
                        .padding(.top, 40)

                    Text("Modifica Nome Utente")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Inserisci un nuovo nome utente per il tuo Account.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("I tuoi dati di LavoraMi sono completamente privati e protetti, potrai richiederli quando vuoi selezionando \"Richiedi i tuoi dati\".")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.gray)
                        
                        TextField("Nome Utente", text: $newUsername)
                            .textInputAutocapitalization(.words)
                            .keyboardType(.alphabet)
                            .keyboardShortcut(.end)
                            .disabled(auth.isLoading)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(
                        colorScheme == .dark ? Color(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)) : Color(UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    Button {
                        Task {
                            do {
                                try await auth.updateUserName(newUserName: newUsername)
                                fullName = newUsername
                                presentationMode.wrappedValue.dismiss()
                                newUsername = ""
                            }
                            catch {}
                        }
                    } label: {
                        Text("Continua")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(isUsernameValid() ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.top, 10)
                    .disabled(isUsernameValid())
                    
                    if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        Text("Il Nome Utente non può essere vuoto.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines) == fullName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        Text("Il nuovo Nome Utente non può essere uguale al tuo Nome Utente attuale.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else if(newUsername.trimmingCharacters(in: .whitespacesAndNewlines).count < 3) {
                        Text("Il Nome Utente non può contenere meno di 3 caratteri.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Personalizza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        fullName = fullName
        presentationMode.wrappedValue.dismiss()
    }
    
    private func isUsernameValid() -> Bool {
        /// This method is a refactor one and check if the new Username of the user is valid and can be saved into the Database.
        /// - Returns: A boolean value based from 3 rules: 1) Username cannot be empty, 2) Username can't be equal to the old username, 3) Minimum characters of the new username: 3
        return newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newUsername.trimmingCharacters(in: .whitespacesAndNewlines) == fullName.trimmingCharacters(in: .whitespacesAndNewlines) || (newUsername.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
    }
}


struct AccountDatasInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @StateObject var authManager: AuthManager
    
    @State var saveFavoritesData: Bool
    @State var saveYourLinesData: Bool
    @State var isLoading: Bool = true
    @State var errorFetching: Bool = false
    @Binding var currentSyncStatus: String
    @Binding var currentSyncStatusIcon: String
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @AppStorage("linesSelected") private var linesSelected: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image("cloudIcon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.red)
                        .padding(.top, 40)

                    Text("Scegli i tuoi Dati")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Scegli che tipologia di dati vuoi che vengano salvati nei nostri Database, per poterci accedere sempre dal tuo Account.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("I tuoi dati di LavoraMi sono completamente privati e protetti, potrai richiederli quando vuoi selezionando \"Richiedi i tuoi dati\".")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("Dati da Salvare")
                            .foregroundColor(.secondary)
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom, -20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $saveFavoritesData) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                                
                                Text("Linee Preferite")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .disabled(isLoading || errorFetching)
                        .onChange(of: saveFavoritesData) {
                            Task {
                                let res: Bool
                                try await authManager.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                                
                                if(saveFavoritesData) { res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected) }
                                else if(!saveFavoritesData && saveYourLinesData){ res = await authManager.saveDatasToDb(favorites: [], yourLines: linesSelected) }
                                else{res = await authManager.saveDatasToDb(favorites: [], yourLines: [])}
                                
                                if(!saveFavoritesData && !saveYourLinesData) {
                                    currentSyncStatus = String(localized: .nonSincronizzato)
                                    currentSyncStatusIcon = "cloudDisabled"
                                }
                                else {
                                    currentSyncStatus = String(localized: .sincronizzato)
                                    currentSyncStatusIcon = "cloudSynced"
                                }
                                
                                print("RESULT: \(res)")
                            }
                        }
                        .tint(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Toggle(isOn: $saveYourLinesData) {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                                
                                Text("Le tue linee")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .disabled(isLoading || errorFetching)
                        .onChange(of: saveYourLinesData) {
                            Task {
                                let res: Bool
                                
                                try await authManager.saveUserPreferences(enableFavorites: saveFavoritesData, enableYourLines: saveYourLinesData)
                                
                                if(saveYourLinesData) { res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected) }
                                else if(!saveYourLinesData && saveFavoritesData){ res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: []) }
                                else{res = await authManager.saveDatasToDb(favorites: [], yourLines: [])}
                                
                                if(!saveFavoritesData && !saveYourLinesData) {
                                    currentSyncStatus = String(localized: .nonSincronizzato)
                                    currentSyncStatusIcon = "cloudDisabled"
                                }
                                else {
                                    currentSyncStatus = String(localized: .sincronizzato)
                                    currentSyncStatusIcon = "cloudSynced"
                                }
                                
                                print("RESULT: \(res)")
                            }
                        }
                        .tint(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        if(isLoading && !errorFetching) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.red)
                                Text("Caricamento...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                            .padding(.leading, 5)
                        }
                        if(errorFetching) {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .foregroundStyle(.red)
                                Text("Errore di connessione.")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                            .padding(.leading, 5)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Preferenze Dati")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear{
                Task {
                    let res: UserPreferencesDatas = await authManager.fetchUserPreferences()
                    
                    saveYourLinesData = res.enable_your_lines
                    saveFavoritesData = res.enable_favorites
                    errorFetching = res.user_email == ""
                    
                    isLoading = false
                }
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct AdvancedOptionsView: View {
    @AppStorage("showErrorMessages") var showErrorMessages: Bool = false
    @AppStorage("showStrikeBanner") var showStrikeBanner: Bool = true
    @AppStorage("requireFaceID") var requireFaceID: Bool = true
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("showTranslateButton") var showTranslateButton: Bool = false
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @State private var openWidgetLine: Bool = DataManager.shared.getOpenWidgetLine()
    private var currentDeviceBiometric: BiometricType = BiometricAuth.getBiometricType()
    @State private var presentedCacheAlert = false
    
    var iphoneGenIcon: String {
        let height = UIScreen.main.bounds.height
        
        switch height {
            case 852, 932:
                return "iphone.gen3.radiowaves.left.and.right"
            case 812, 844, 896, 926:
                return "iphone.gen2.radiowaves.left.and.right"
            default:
                return "iphone.gen1.radiowaves.left.and.right"
        }
    }
    
    var body: some View {
        List{
            Section(footer: Text("Mostra il banner degli scioperi nella Home quando sono presenti.")){
                Toggle(isOn: $showStrikeBanner){
                    Label("Mostra banner Scioperi", systemImage: "megaphone.fill")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Mostra le tue ricerche recenti nella pagina delle Linee.")){
                Toggle(isOn: $showRecentSearches){
                    Label("Mostra Ricerche Recenti", systemImage: "text.magnifyingglass")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Attiva i Feedback di vibrazione su alcune schermate.")){
                Toggle(isOn: $feedbacksEnabled){
                    Label("Attiva Feedback Vibrazione", systemImage: iphoneGenIcon)
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            if(Locale.current.language.languageCode?.identifier == "it"){
                Section(footer: Text("Mostra il pulsante per tradurre i lavori anche nella lingua italiana.")){
                    Toggle(isOn: $showTranslateButton){
                        Label("Mostra Pulsante Traduci", systemImage: "translate")
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            }
            Section(footer: Text("Apre la linea selezionata per il Widget quando ci clicchi sopra. Se disattivata, apre l'app nella schermata Home.")){
                Toggle(isOn: $openWidgetLine){
                    Label("Apri Linea Widget", systemImage: "arrow.branch")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            .onChange(of: openWidgetLine) { _, newValue in
                DataManager.shared.setOpenWidgetLine(newValue)
            }
            Section(footer: Text("Richiedi \(getBiometricTypeByEnum()) per bloccare e sbloccare la sezione del tuo Account. Per modificare questa opzione dovrai autenticarti con \(getBiometricTypeByEnum()).")){
                Toggle(isOn: $requireFaceID){
                    Label("Richiedi \(getBiometricTypeByEnum())", systemImage: (getBiometricTypeByEnum() == "Codice") ? "lock.fill" : getBiometricTypeByEnum().lowercased())
                }
                .onChange(of: requireFaceID) { oldValue, newValue in
                    if(newValue == false){
                        BiometricAuth.authenticate{
                            print("FaceID Recognized!")
                            requireFaceID = false
                        } onFailure: { error in
                            print("Error during read of FaceID")
                            requireFaceID = true
                        }
                    }
                    else{
                        requireFaceID = requireFaceID
                    }
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Seleziona la modalità in cui aprire i link.")){
                Label("Apri link:", systemImage: "network")
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Picker(selection: $howToOpenLinks, content: {
                    ForEach(linkOpenTypes.allCases) { filter in
                        Text(filter.localizedID).tag(filter)
                            .foregroundStyle(Color("TextColor"))
                    }
                }, label: {
                    Text("")
                })
                
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section(footer: Text("Mostra messaggi di errore quando fallisce il Download dei dati.")){
                Toggle(isOn: $showErrorMessages){
                    Label("Mostra Messaggi Errore", systemImage: "exclamationmark.bubble.fill")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
            Section(footer: Text("Elimina la memoria Cache dal dispositivo, liberando spazio su disco.")){
                Button(role: .destructive) {
                    if(feedbacksEnabled){
                        HapticManager.shared.trigger()
                    }
                    presentedCacheAlert = true
                } label: {
                    Label("Pulisci Memoria Cache", systemImage: "trash.fill")
                }
                .confirmationDialog("Sei sicuro?", isPresented: $presentedCacheAlert) {
                    Button("Annulla", role: .cancel) { }
                    Button("Continua", role: .destructive) {
                        clearAllCache()
                    }
                } message: {
                    Text("Sei sicuro di voler pulire la memoria Cache?")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
        }
        .padding(.bottom, 20)
        .navigationTitle("Opzioni Avanzate")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
    }
    
    func getBiometricTypeByEnum() -> String {
        switch(currentDeviceBiometric){
            case .touchID:
                return "TouchID"
            case .faceID:
                return "FaceID"
            default:
                return "Codice"
        }
    }
    
    func clearAllCache() {
        URLCache.shared.removeAllCachedResponses()
        
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

struct NotificationsView: View {
    @AppStorage("workScheduledNotifications") var workScheduledNotifications: Bool = true
    @AppStorage("workInProgressNotifications") var workInProgressNotifications: Bool = true
    @AppStorage("strikeNotifications") var strikeNotifications: Bool = true
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("enablePushNotifications") var enablePushNotifications: Bool = true
    @AppStorage("linesFavorites") var linesFavorites: [String] = []
    @AppStorage("notificationConsent") var notificationConsent: Bool = false
    
    static var defaultTime: Date {
        //MARK: SET DEFAULT VALUE OF DATEPICKER
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    @AppStorage("dateSchedule") var dateSchedule: Date = defaultTime
    
    @ObservedObject var viewModel: WorkViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if(notificationConsent) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $enableNotifications) {
                        HStack (spacing: 15){
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.red)
                                .scaleEffect(1.5)
                            Text("Notifiche")
                                .font(.system(size: 20))
                                .bold()
                        }
                    }
                    .tint(.red)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .disabled(!notificationConsent)
                    
                    Text("Imposta tutte le notifiche sottostanti su uno stato.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                .padding(.horizontal)
                .onChange(of: enableNotifications) { oldValue, newValue in
                    workScheduledNotifications = enableNotifications
                    workInProgressNotifications = enableNotifications
                    strikeNotifications = enableNotifications
                    enablePushNotifications = enableNotifications
                    
                    //SYNC NOTIFICATIONS
                    viewModel.fetchVariables()
                    NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                }
            }

            if(notificationConsent){
                List {
                    Section("Notifiche Lavori") {
                        Toggle(isOn: $workScheduledNotifications) {
                            Label("Notifiche Inizio Lavori", systemImage: "bell.badge.fill")
                        }
                        .onChange(of: workScheduledNotifications){
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }
                        .disabled(!enableNotifications)
                        
                        Toggle(isOn: $workInProgressNotifications) {
                            Label("Notifiche Fine Lavori", systemImage: "bell.badge.fill")
                        }
                        .onChange(of: workInProgressNotifications){
                            NotificationManager.shared.syncNotifications(for: viewModel.items, favorites: linesFavorites)
                        }
                        .disabled(!enableNotifications)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Section("Altre Notifiche") {
                        Toggle(isOn: $strikeNotifications) {
                            Label("Notifiche Scioperi", systemImage: "megaphone.fill")
                        }
                        .onChange(of: strikeNotifications){
                            viewModel.fetchVariables()
                        }
                        .disabled(!enableNotifications)
                        Toggle(isOn: $enablePushNotifications) {
                            Label("Notifiche In Tempo Reale", systemImage: "bell.and.waves.left.and.right.fill")
                        }
                        .onChange(of: enablePushNotifications) { oldValue, enabled in
                            NotificationCenter.default.post(name: NSNotification.Name("pushNotificationsToggled"), object: enabled)
                        }
                        .disabled(!enableNotifications)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Section(header: Text("Impostazioni Notifiche"), footer: Text("Modifica l'orario di arrivo delle notifiche.")){
                        VStack{
                            DatePicker(selection: $dateSchedule, displayedComponents: .hourAndMinute){
                                Label("Orario Notifiche", systemImage: "clock.badge.fill")
                            }
                            .disabled(!enableNotifications)
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            else {
                Label {
                    Text("Permesso Negato")
                        .font(.system(size: 25))
                } icon: {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 25))
                }
                
                Text("Non hai dato il permesso per ricevere notifiche. Vai su Impostazioni > App > LavoraMi ed attiva le notifiche.")
                    .padding()
                    .font(.system(size: 13))
                    .bold()
                
                Link("Apri Impostazioni", destination: URL(string: UIApplication.openSettingsURLString)!)
                    .tint(.red)
            }
        }
        .onAppear{
            NotificationManager.shared.getPermissionOfNotifications()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Notifiche")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoView: View {
    let device = UIDevice.current
    
    @Environment(\.openURL) private var openURLAction
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var mailData: ComposeMailData = ComposeMailData(subject: String(localized: .titoloBugReport), recipients: ["info@lavorami.it"], message: "", attachments: nil)
    @State private var mailDataInfoReport: ComposeMailData = ComposeMailData(subject: String(localized: .mailInformazioni), recipients: ["report-incorrettezze@lavorami.it"], message: "", attachments: nil)
    @State private var showMailView: Bool = false
    @State private var showMailViewReport: Bool = false
    
    var body: some View {
        Section{
            HStack{
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("LavoraMi")
                    .font(.system(size: 35))
                    .bold()
            }
            .padding(.bottom, 10)
            Text("\(Bundle.main.shortVersion) (Build \(Bundle.main.buildVersion))")
            Divider()
                .padding(.top, 10)
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

                    Tutti i dati visualizzati in questa applicazione (orari, stati del servizio, avvisi) sono raccolti da fonti pubbliche al solo scopo di migliorarne la comprensione ed a solo scopo informativo.
                    
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
                        
                        Text("Sviluppatore Principale:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatore iOS:")
                            .font(.system(size: 20))
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                            .padding(.top, -5)
                        
                        Text("Sviluppatori Android:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Andrea Filice")
                            .bold()
                            .font(.system(size: 25))
                        Text("Alessandro Rebuscini")
                            .bold()
                            .font(.system(size: 25))
                        Text("Tommaso Ruggeri")
                            .bold()
                            .font(.system(size: 25))
                        
                        Text("Sviluppatori Web:")
                            .font(.system(size: 20))
                            .padding(.top, 20)
                        Text("Riccardo De Diana")
                            .bold()
                            .font(.system(size: 25))
                        Text("Simone Gallotti")
                            .bold()
                            .font(.system(size: 25))
                    }
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Seguici su")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    Button {
                        let url = URL(string: "https://www.instagram.com/lavoramiapp/")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Instagram")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.tiktok.com/@lavoramiapp")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("tiktok")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("TikTok")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.facebook.com/profile.php?id=61593590085842")!
                        openURLAction(url)
                    } label: {
                        HStack{
                            Image("facebook")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Facebook")
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Contatti")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    
                    Button {
                        showMailView = true
                    } label: {
                        Label("Segnala un bug", systemImage: "ladybug.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        showMailViewReport = true
                    } label: {
                        Label("Segnala Incorrettezze", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it\((colorScheme == .dark) ? "?theme=dark" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Sito web", systemImage: "network")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    .sheet(isPresented: $showMailView) {
                        MailView(data: $mailData) { result in
                            print(result)
                        }
                    }
                    .sheet(isPresented: $showMailViewReport) {
                        MailView(data: $mailDataInfoReport) { result in
                            print(result)
                        }
                    }
                    Spacer()
                }
                Divider().padding(.top, 10)
                Section(){
                    Text("Informazioni")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top, 20)
                    NavigationLink(destination: LibrariesView()) {
                        Label("Librerie Open-Source", systemImage: "books.vertical.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/privacyPolicy\((colorScheme == .dark) ? "" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    Button {
                        let url = URL(string: "https://www.lavorami.it/termsofservice\((colorScheme == .dark) ? "" : "?theme=light")")!
                        
                        if(howToOpenLinks == .inApp) {
                            selectedURL = url
                        }
                        else {
                            openURLAction(url)
                        }
                    } label: {
                        Label("Termini di Servizio", systemImage: "doc.text.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
                .ignoresSafeArea(.all)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibraryRowView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(version)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }

            HStack {
                Text(license)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(copyright)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cornerRadius(12)
    }
}

struct LibraryDetailView: View {
    let name: String
    let version: String
    let license: String
    let copyright: String
    let licenseText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Informazioni sul componente")
                        .font(.title2).bold()
                        .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nome:").font(.caption).foregroundColor(.secondary)
                            Text(name).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Versione:").font(.caption).foregroundColor(.secondary)
                            Text(version).font(.body).bold()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Licenza:").font(.caption).foregroundColor(.secondary)
                            Text(license).font(.body).bold()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Copyright")
                        .font(.title2).bold()

                    Text(copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Testo della licenza")
                        .font(.title2).bold()

                    Text(licenseText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HowAppWorksView: View {
    let interchangeInfo: InterchangeInfo = .init(name: "Romolo", lines: ["M2", "R31", "S9", "S19"], typeOfInterchange: "lightrail.fill")
    let workItem: WorkItem = .init(title: "Rallentamenti", titleIcon: "clock.badge.fill", typeOfTransport: "train.side.front.car", roads: "Palazzolo, Camnago Lentate, Seveso", lines: ["R16", "S2", "S4"], startDate: ISO8601DateFormatter().date(from: "2026-02-23T00:00:00+01:00") ?? Date(), endDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(), details: "Lavori di potenziamento infrastrutturale nella tratta Palazzolo, Camnago Lentate, Seveso con modifiche alla circolazione dei treni", company: "Trenord")
    let stations: [MetroStation] = StationsDB.stationsM1;
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                SectionHeader(icon: "chart.bar.fill", title: String(localized: .barraDiProgresso))
                Text("Vedi visivamente a che punto sono i lavori e quando è prevista la fine del disagio (basato su data di inizio e fine lavori PREVISTI).")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                CardView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("12 Nov 2025")
                                .font(.system(size: 12))
                            Spacer()
                            Text("15 Dic 2026")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)

                        ProgressView(value: 0.38)
                            .progressViewStyle(.linear)
                            .tint(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                
                SectionDivider()
                
                SectionHeader(icon: "arrow.branch", title: String(localized: .scegliLaTuaLinea))
                Text("Salva fra i preferiti la linea che usi ogni giorno e quando ci sarà un lavoro su di essa, sarai già aggiornato.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                CardView {
                    HStack {
                        Image(systemName: "bus.fill")
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                        Text("Linee Movibus")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .frame(width: 18, height: 18)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(.secondarySystemBackground))
                }
                
                Text("Oppure salva una linea nella sezione \"Le tue Linee\" per vedere, tramite l'apposito filtro, solo i lavori che interessano a te.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                CardView {
                    HStack {
                        Text("M1")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(getColor(for: "M1"))
                            )
                        Text("Metro M1")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(red: 1, green: 93 / 255, blue: 162 / 255))
                            .frame(width: 18, height: 18)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(.secondarySystemBackground))
                }

                SectionDivider()

                SectionHeader(icon: "arrow.left.arrow.right", title: String(localized: .visualizzaGliInterscambi))

                Text("Visualizza le linee che interscambiano con la TUA linea, oppure sui bus visualizza dove fanno capolinea con una fermata di interscambio.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                InterchangeRow(interchange: interchangeInfo, currentLine: "M1", isFirst: false, isLast: false)
                    .padding(.top, 20)
                SectionDivider()
                SectionHeader(icon: "hand.raised.fill", title: String(localized: .fermataCantiere))

                Text("Non solo \"lavori in via\", ti spieghiamo che tipo di lavoro si sta svolgendo ed anche le conseguenze che può portare quel cantiere (Deviazioni, Fermate Sospese...)")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                WorkInProgressRow(item: workItem)
                    .padding()

                SectionDivider()

                SectionHeader(icon: "map.fill", title: String(localized: .visualizzaLaMappa))

                Text("Visualizza i percorsi delle linee che preferisci sulla mappa, per non perdersi e per sapere sempre dove vai.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .frame(width: 380, height: 280)
                    .overlay(
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 45.4682, longitude: 9.17588),
                            span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
                        ))) {
                            let lineColor = getColor(for: "M1")
                            
                            MapPolyline(coordinates: stations.filter { $0.branch == "Main" }.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                            let pagano = stations.first(where: { $0.name == "Pagano" })!
                            let bisceglie = stations.first(where: { $0.name == "Bisceglie" })!
                            let rhoBranch = [pagano] + stations.filter { $0.branch == "Rho" }
                            MapPolyline(coordinates: rhoBranch.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                            
                            let bisceglieBranch = [pagano] + stations.filter { $0.branch == "Bisceglie" }
                            MapPolyline(coordinates: bisceglieBranch.map(\.coordinate))
                                .stroke(lineColor, lineWidth: 5)
                        
                            let bisceglieBranchNew = [bisceglie] + stations.filter { $0.branch == "Bisceglie - New" }
                            MapPolyline(coordinates: bisceglieBranchNew.map(\.coordinate))
                            .stroke(lineColor, style: StrokeStyle(lineWidth: 4, dash: [6, 6]))
                        
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
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.top, 10)

                SectionDivider()

                SectionHeader(icon: "bell.fill", title: String(localized: .aggiornatoSempre))

                Text("Ti avvisiamo il giorno prima della fine dei lavori, quando spuntano nuovi cantieri sulla tua linea preferita ed anche quando sarà un Venerdì no.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                SectionDivider()

                Text("Tutti gli esempi riportati sono a scopo esemplificativo, possono essere eventi attualmente in corso o passati.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
            }
            .padding(.top, 10)
        }
        .navigationTitle("Funzioni dell'App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.red)
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.red)
        }
        .padding(.top, 10)
    }
}

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 56/255, green: 56/255, blue: 58/255))
            .frame(height: 1)
            .padding(20)
    }
}

private struct CardView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 10)
    }
}

struct LibrariesView: View {
    let libraries: [LibraryDetailView] = [
        LibraryDetailView(
            name: "abseil",
            version: "1.2024072200.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 The Abseil Authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "AppCheck",
            version: "11.3.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2020 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Firebase",
            version: "12.18.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAdsOnDeviceConversion",
            version: "3.6.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAppMeasurement",
            version: "12.18.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleDataTransport",
            version: "10.1.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleMobileAds",
            version: "13.9.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleUserMessagingPlatform",
            version: "3.1.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleUtilities",
            version: "8.1.3",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "gRPC",
            version: "1.69.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2015 gRPC authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GTMSessionFetcher",
            version: "5.3.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2014 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "InteropForGoogle",
            version: "101.0.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "leveldb",
            version: "1.22.5",
            license: "BSD 3-Clause License",
            copyright: "Copyright (c) 2011 The LevelDB Authors",
            licenseText: """
            Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

            1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
            2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
            3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
            """
        ),
        LibraryDetailView(
            name: "nanopb",
            version: "2.30910.1",
            license: "Zlib License",
            copyright: "Copyright (c) 2011 Petteri Aimonen",
            licenseText: """
            This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

            Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

            1. The origin of this software must not be misrepresented.
            2. Altered source versions must be plainly marked as such.
            3. This notice may not be removed or altered from any source distribution.
            """
        ),
        LibraryDetailView(
            name: "Promises",
            version: "2.4.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2018 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Supabase",
            version: "2.55.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Supabase",
            licenseText: """
            MIT License

            Copyright (c) 2021 Supabase

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-asn1",
            version: "1.7.2",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2022 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-clocks",
            version: "1.1.1",
            license: "MIT License",
            copyright: "Copyright (c) 2022 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2022 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-concurrency-extras",
            version: "1.4.1",
            license: "MIT License",
            copyright: "Copyright (c) 2023 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2023 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-crypto",
            version: "4.5.2",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-http-types",
            version: "1.7.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "SwiftUIMailView",
            version: "1.0.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Gordan Glavaš",
            licenseText: """
            MIT License

            Copyright (c) 2021 Gordan Glavaš

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView (
            name: "xctest-dynamic-overlay",
            version: "1.13.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2021 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        )
    ]
    
    var body: some View {
        List {
            ForEach(libraries, id: \.name) { library in
                NavigationLink(destination: LibraryDetailView(
                    name: library.name,
                    version: library.version,
                    license: library.license,
                    copyright: library.copyright,
                    licenseText: library.licenseText
                )) {
                    LibraryRowView(
                        name: library.name,
                        version: library.version,
                        license: library.license,
                        copyright: library.copyright
                    )
                }
            }
        }
        .navigationTitle("Librerie Open-Source")
    }
}

struct RequestDataDownload: View {
    @AppStorage("emailSaved") var emailSaved: String = ""
    
    @State private var mailData: ComposeMailData = ComposeMailData(subject: "Richiesta di Dati", recipients: ["info@lavorami.it"], message: "Buongiorno,\nVorrei richiedere l'invio dei miei dati in formato JSON dell'Account con mail: mail@mail.com", attachments: nil)
    @State private var showMailView: Bool = false
    @State private var selectedFileType: fileFormatType = .json
    
    @Binding var isRequiringData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.and.background.dotted")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.red)
                    
                    Text("Richiedi i tuoi Dati")
                        .font(.system(size: 30, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Invia una richiesta al nostro Team per scaricare i tuoi dati.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            List{
                Section(footer: Text("Seleziona il formato in cui i tuoi dati verranno esportati.")){
                    Label("Formato del File:", systemImage: "arrow.down.doc.fill")
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    Picker(selection: $selectedFileType, content: {
                        ForEach(fileFormatType.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                                .foregroundStyle(Color("TextColor"))
                        }
                    }, label: {
                        Text("")
                    })
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
            }
            Spacer()
            Button(action: {
                let localizedString = String(localized: .messaggioEmailDati(selectedFileType.rawValue, emailSaved))
                let formattedBody = localizedString.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "")
                mailData = ComposeMailData(subject: String(localized: .richiestaDeiDati), recipients: ["info@lavorami.it"], message: formattedBody, attachments: nil)
                showMailView = true
            }) {
                Label("Richiedi Dati", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            .sheet(isPresented: $showMailView) {
                MailView(data: $mailData) { result in
                    print(result)
                }
            }
        }
        .padding()
        .navigationTitle("Aiuto")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .onAppear{
            isRequiringData = true
        }
    }
}

//MARK: LINES VIEW
struct LineRow: View {
    let line: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    let accessibilityStatus: String
    let stations: [MetroStation]
    @State private var supportedLines: [String] = ["1", "2", "3", "4", "5", "7", "9", "10", "14", "15", "16", "19", "24", "27", "31", "33"]
    @ObservedObject var viewModel: WorkViewModel
    var onTap: (() -> Void)? = nil

    private var isDetailView: Bool {
        (typeOfTransport != String(localized: .tram) || supportedLines.contains(line))
        && typeOfTransport != "Movibus"
        && typeOfTransport != "STAV"
        && typeOfTransport != "NET"
        && typeOfTransport != "Autoguidovie"
        && typeOfTransport != "STAR Mobility"
    }

    @ViewBuilder
    private var destination: some View {
        if isDetailView {
            LineDetailView(
                lineName: line,
                typeOfTransport: typeOfTransport,
                branches: branches,
                waitMinutes: waitMinutes,
                workScheduled: getWorkScheduled(line: (typeOfTransport.uppercased().contains(String(localized: .filobus).uppercased())) ? "Filobus \(line)" : line, viewModel: viewModel),
                workNow: getWorkNow(line: (typeOfTransport.uppercased().contains(String(localized: .filobus).uppercased()) ? "Filobus \(line)" : line), viewModel: viewModel),
                viewModel: viewModel,
                stations: stations,
                accessibilityStatus: accessibilityStatus,
                onAppear: { onTap?() }
            )
        } else {
            LineSmallDetailedView(
                lineName: line,
                typeOfTransport: typeOfTransport,
                branches: branches,
                waitMinutes: waitMinutes,
                workScheduled: getWorkScheduled(line: line, viewModel: viewModel),
                workNow: getWorkNow(line: line, viewModel: viewModel),
                accessibilityStatus: accessibilityStatus,
                viewModel: viewModel,
                onAppear: { onTap?() }
            )
        }
    }

    var body: some View {
        NavigationLink {destination} label: {
            HStack(spacing: 12) {
                Text(line)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: line))
                    )

                if line == "MXP1" || line == "MXP2" {Text(typeOfTransport)}
                else {Text("\(typeOfTransport) \(line)")}
            }
            .padding(.vertical, 4)
        }
    }
}

struct LinesView: View {
    @Environment(\.openURL) private var openURLAction
    @ObservedObject var viewModel: WorkViewModel
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @AppStorage("showRecentSearches") var showRecentSearches: Bool = true
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true

    @State private var searchInput: String = ""
    @State private var selectedURL: URL?
    @State private var showDeletePopUp: Bool = false
    @FocusState private var isSearchFocused: Bool

    @StateObject private var adMobManager = AdMobManager(totalDesired: 2)
    @ObservedObject private var consentManager = ConsentManager.shared
    @State private var adsRequested: Bool = false

    private var shouldShowAdsAfterRecent: Bool {
        showRecentSearches && recentlySearchedLines.count >= 3
    }

    @ViewBuilder
    private var supportLavoraMiSection: some View {
        if !adMobManager.nativeAds.isEmpty {
            Section {
                ForEach(Array(adMobManager.nativeAds.enumerated()), id: \.offset) { _, ad in
                    CompactNativeAdView(nativeAd: ad)
                        .frame(height: 60)
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Supporta LavoraMi")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.primary)
                        .textCase(nil)

                    Text("Aiutaci a sostenere LavoraMi!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemBackground))
        }
    }

    private func requestLinesAdsIfNeeded() {
        guard consentManager.isReady, !adsRequested else { return }
        if let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String {
            adsRequested = true
            adMobManager.loadNativeAds(adUnitID: adUnitID)
        }
    }

    // MARK: - Search helpers
    private func matches(_ line: LineInfo, query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        
        let typeKeywords: [String: [String]] = [
            "Metro": ["metro", "metropolitana", "m"],
            "Suburbano": ["suburbano", "s"],
            "Regio express": ["regio", "express", "re"],
            "Regionale": ["regio", "regionale", "r"],
            String(localized: .tram): ["tram", "tranvía", "t"],
            String(localized: .filobus): ["filobus", "9"],
            "Movibus": ["bus", "movibus", "z"],
            "Nordest Trasporti": ["z", "bus", "net"],
            "STAR Mobility": ["bus", "star", "z"],
            "STAV": ["stav", "bus", "z"],
            "Autoguidovie": ["autoguidovie", "bus", "z"],
            "Malpensa Express": ["malpensa", "malpensa express", "express", "mxp"]
        ]
        
        let name = line.name.lowercased()
        let type = line.type.lowercased()
        let tokens = q.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        
        for token in tokens {
            if name.contains(token) { continue }
            if type.contains(token) { continue }
            let hasNumbers = token.rangeOfCharacter(from: .decimalDigits) != nil
            if !hasNumbers,
               let synonyms = typeKeywords[line.type]?.map({ $0.lowercased() }),
               synonyms.contains(where: { token.hasPrefix($0) || $0.hasPrefix(token) }) {
                continue
            }
            if token.allSatisfy({ $0.isNumber }) && name.contains(token) { continue }
            
            return false
        }
        return true
    }

    private func filtered(_ items: [LineInfo]) -> [LineInfo] {
        guard !searchInput.isEmpty else { return items }
        return items.filter { matches($0, query: searchInput) }
    }

    var filteredMetros: [LineInfo] { filtered(metros) }
    var filteredSuburban: [LineInfo] { filtered(suburban) }
    var filteredRegioExpress: [LineInfo] { filtered(regioExpress) }
    var filteredRegional: [LineInfo] { filtered(regionalLines) }
    var filteredTrams: [LineInfo] { filtered(trams) }
    var filteredFilobus: [LineInfo] { filtered(filobus) }
    var filteredMovibus: [LineInfo] { filtered(bus) }
    var filteredNET: [LineInfo] { filtered(net) }
    var filteredSTAR: [LineInfo] { filtered(star) }
    var filteredSTAV: [LineInfo] { filtered(stav) }
    var filteredAutoguidovie: [LineInfo] { filtered(autoguidovie) }
    var filteredCrossBorders: [LineInfo] { filtered(crossBorderLines) }
    var filteredMalpensaExpress: [LineInfo] { filtered(malpensaExpress) }
    
    struct RecentLine: Identifiable, Codable, Hashable {
        let id: UUID
        let name: String
        let branches: String
        let type: String
        let waitMinutes: String
        let accessibilityStatus: String
        
        init(from lineInfo: LineInfo) {
            self.id = lineInfo.id
            self.name = lineInfo.name
            self.branches = lineInfo.branches
            self.type = lineInfo.type
            self.waitMinutes = lineInfo.waitMinutes
            self.accessibilityStatus = lineInfo.accessibilityStatus
        }
    }
    
    @AppStorage("recentlySearchedLinesData") private var recentlySearchedLinesData: Data = Data()

    var recentlySearchedLines: [RecentLine] {
        get { (try? JSONDecoder().decode([RecentLine].self, from: recentlySearchedLinesData)) ?? [] }
        set { recentlySearchedLinesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    func fullLineInfo(for name: String) -> LineInfo? {
        let all = metros + suburban + regioExpress + regionalLines + crossBorderLines + malpensaExpress + trams + filobus + bus + net + stav + star + autoguidovie
        return all.first { $0.name == name }
    }

    func addToRecent(_ line: LineInfo) {
        var recent = recentlySearchedLines
        recent.removeAll { $0.name == line.name }
        recent.insert(RecentLine(from: line), at: 0)
        if recent.count > 5 { recent = Array(recent.prefix(5)) }
        recentlySearchedLinesData = (try? JSONEncoder().encode(recent)) ?? Data()
    }
    
    var metros: [LineInfo] {
        [
            LineInfo(name: "M1", branches: "Sesto F.S. - Rho Fiera / Bisceglie", type: "Metro", waitMinutes: "Sesto FS: 3 min | Rho/Bisceglie: 7-8 min", stations: StationsDB.stationsM1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M2", branches: "Gessate / Cologno - Assago / Abbiategrasso", type: "Metro", waitMinutes: "Gessate: 12-15 min | Assago: 9-10 min", stations: StationsDB.stationsM2, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M3", branches: "Comasina - San Donato", type: "Metro", waitMinutes: "4-5 min", stations: StationsDB.stationsM3, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M4", branches: "Linate Aereoporto - San Cristoforo", type: "Metro", waitMinutes: "2-3 min",stations: StationsDB.stationsM4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "M5", branches: "Bignami - San Siro Stadio", type: "Metro", waitMinutes: "4 min", stations: StationsDB.stationsM5, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var suburban: [LineInfo] {
        [
            LineInfo(name: "S1", branches: ((viewModel.enablePassanteWork) ? "Milano Bovisa - Lodi" : "Saronno - Lodi"), type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.getStationS1(isPassanteClosed: viewModel.enablePassanteWork), accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S2", branches: "Mariano Comense - Milano Rogoredo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS2,  accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S3", branches: "Saronno - Milano Cadorna", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S4", branches: "Camnago Lentate - Milano Cadorna", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS4, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S5", branches: ((viewModel.enablePassanteWork) ? "Varese - Milano Lambrate - Pioltello" : "Varese - Treviglio"), type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.getStationS5(isPassanteClosed: viewModel.enablePassanteWork), accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S6", branches: "Novara - Rho", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS6, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S7", branches: "Lecco - Milano Porta Garibaldi", type: String(localized: .suburbano), waitMinutes: "30 min - 1 \(String(localized: .ora))", stations: StationsDB.stationsS7, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S8", branches: "Lecco - Carnate - Milano Porta Garibaldi", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS8, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S9", branches: "Saronno - Albairate Vermezzo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS9, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "S11", branches: "Milano Porta Garibaldi - Como S. Giovanni", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS11, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S12", branches: "Melegnano - Milano Bovisa", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS12, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S13", branches: ((viewModel.enablePassanteWork) ? "Milano Rogoredo - Pavia" : "Garbagnate Milanese - Pavia"), type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.getStationS13(isPassanteClosed: viewModel.enablePassanteWork), accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S19", branches: "Albairate Vermezzo - Milano Rogoredo", type: String(localized: .suburbano), waitMinutes: "30 min", stations: StationsDB.stationsS19, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S31", branches: "Brescia - Iseo", type: String(localized: .suburbano), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.stationsS31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile))
        ]
    }
    
    var regionalLines: [LineInfo] {
        [
            LineInfo(name: "R1", branches: "Bergamo - Brescia", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r1, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R2", branches: "Bergamo - Treviglio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R3", branches: "Brescia - Iseo - Breno", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R4", branches: "Brescia - Treviglio - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R5", branches: "Brescia - Cremona", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r5, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R6", branches: "Cremona - Treviglio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r6, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R7", branches: "Lecco - Bergamo", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r7, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R8", branches: "Brescia - Piadena - Parma", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r8, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R9", branches: "Rovato - Bornato - Iseo", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r9, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R11", branches: "Colico - Chiavenna", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r11, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R12", branches: "Sondrio - Tirano", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r12, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R13", branches: "Lecco - Colico - Sondrio", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r13, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R14", branches: "Bergamo - Carnate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r14, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R15", branches: "Seregno - Carnate", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r15, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R16", branches: "Asso - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r16, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R17", branches: "Como - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r17, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R18", branches: "Como - Molteno - Lecco", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r18, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R21", branches: "Luino - Gallarate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r21, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R22", branches: "Varese - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r22, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R23", branches: "Domodossola - Gallarate - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r23, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R24", branches: "Laveno - Sesto Calende", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r24, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R25", branches: "Novara - Mortara", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r25, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R27", branches: "Novara - Saronno - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r27, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R31", branches: "Mortara - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R32", branches: "Mortara - Alessandria", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r32, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R33", branches: "Pavia - Voghera", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r33, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R34", branches: "Stradella - Pavia - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.r34, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "R35", branches: "Pavia - Torreberetti - Alessandria", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r35, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R36", branches: "Pavia - Mortara - Vercelli", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r36, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R37", branches: "Pavia - Codogno", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r37, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R38", branches: "Piacenza - Lodi - Milano", type: String(localized: .regionale), waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.r38, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "R39", branches: "Codogno - Cremona", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r39, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R40", branches: "Cremona - Mantova", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r40, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "R41", branches: "Voghera - Piacenza", type: String(localized: .regionale), waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.r41, accessibilityStatus: String(localized: .lineaNonAccessibile)),
        ]
    }
    
    var regioExpress: [LineInfo] {
        [
            LineInfo(name: "RE1", branches: "Laveno - Saronno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.re1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE2", branches: "Milano - Bergamo", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "RE3", branches: "Brescia - Iseo - Edolo", type: "Regio Express", waitMinutes: "2 \(String(localized: .ore)) - 1 \(String(localized: .ora))", stations: StationsDB.re3, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE4", branches: "Domodossola - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re4, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE5", branches: "Porto Ceresio - Varese - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re5, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE6", branches: "Verona - Brescia - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re6, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE7", branches: "Como - Saronno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re7, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE8", branches: "Tirano - Lecco - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora)) - 30 min", stations: StationsDB.re8, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE11", branches: "Mantova - Codogno - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re11, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE13", branches: "Asti/Arquata - Pavia - Milano", type: "Regio Express", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.re13, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var crossBorderLines: [LineInfo] {
        [
            LineInfo(name: "S10", branches: "Biasca - Como S. Giovanni", type: "TILO", waitMinutes: "1 \(String(localized: .ora)) - 45 min", stations: StationsDB.tiloS10, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S20", branches: "Castione Arbedo - Locarno", type: "TILO", waitMinutes: "30 min", stations: StationsDB.tiloS20, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S30", branches: "Cadenazzo - Gallarate", type: "TILO", waitMinutes: "2 \(String(localized: .ore))", stations: StationsDB.tiloS30, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "S40", branches: "Como S. Giovanni - Varese", type: "TILO", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.tiloS40, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S50", branches: "Biasca - Malpensa Aereoporto T2", type: "TILO", waitMinutes: "1 \(String(localized: .ora))", stations: StationsDB.tiloS50, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "S90", branches: "Bellinzona - Mendrisio", type: "TILO", waitMinutes: "30 min", stations: StationsDB.tiloS90, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "RE80", branches: "Locarno - Milano Centrale", type: "TILO", waitMinutes: "30 min - 1 \(String(localized: .ora))", stations: StationsDB.tiloRE80, accessibilityStatus: String(localized: .lineaAccessibile))
        ]
    }
    
    var malpensaExpress: [LineInfo] {
        [
            LineInfo(name: "MXP1", branches: "Gallarate - Malpensa T2 - Milano Centrale", type: "Malpensa Express 1", waitMinutes: "30 min", stations: StationsDB.mxp1, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "MXP2", branches: "Malpensa T2 - Milano Cadorna", type: "Malpensa Express 2", waitMinutes: "30 min", stations: StationsDB.mxp2, accessibilityStatus: String(localized: .lineaAccessibile)),
        ]
    }
    
    var trams: [LineInfo] {
        [
            LineInfo(name: "1", branches: "Roserio - Greco", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram1, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "2", branches: "P.Le Negrelli - P.Za Bausan", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram2, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "3", branches: "Duomo M1 M3 - Gratosoglio", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram3, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "4", branches: "Cairoli M1 - Niguarda (Parco Nord)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram4, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "5", branches: "Niguarda (Ospedale) - Ortica", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram5, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "7", branches: "P.Le Lagosta - Q.Re Adriano", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram7, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "9", branches: "Centrale FS M2 M3 - P.Ta Genova M2", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram9, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "10", branches: "P.Za 24 Maggio - V.Le Lunigiana", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram10, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "12", branches: "P.Za Ovidio - Roserio (Ospedale Sacco)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: [], accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "14", branches: "Lorenteggio - Cimitero Maggiore", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram14, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "15", branches: "Duomo M1 M3 - Rozzano (Via G. Rossa)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram15, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "16", branches: "San Siro Stadio M5 - Via Monte Velino", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram16, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "19", branches: "P.Za Castelli - Lambrate FS M2", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram19, accessibilityStatus: String(localized: .lineaNonAccessibile)),
            LineInfo(name: "24", branches: "Piazza Fontana - Vigentino", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram24, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "27", branches: "V.Le Ungheria - Piazza Fontana", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram27, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "31", branches: "Bicocca M5 - Cinisello (1° Maggio)", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram31, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile)),
            LineInfo(name: "33", branches: "P.Le Lagosta - Rimembranze di Lambrate", type: String(localized: .tram), waitMinutes: "5-20 min", stations: StationsDB.tram33, accessibilityStatus: String(localized: .lineaNonAccessibile)),
        ]
    }
    
    var filobus: [LineInfo] {
        [
            LineInfo(name: "90", branches: "\(String(localized: .circolareDestra)) (Lotto M1 M5 - Lodi M3)", type: String(localized: .filobus), waitMinutes: "4-6 min", stations: StationsDB.filobus90, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "91", branches: "\(String(localized: .circolareSinistra)) (Lodi M3 - Lotto M1 M5)", type: String(localized: .filobus), waitMinutes: "4-6 min", stations: StationsDB.filobus91, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "92", branches: "Via Varè (Bovisa FN) - Lodi M3", type: String(localized: .filobus), waitMinutes: "7-10 min", stations: StationsDB.filobus92, accessibilityStatus: String(localized: .lineaAccessibile)),
            LineInfo(name: "93", branches: "V.Le Omero - Lambrate FS", type: String(localized: .filobus), waitMinutes: "10-12 min", stations: StationsDB.filobus93, accessibilityStatus: String(localized: .lineaParzialmenteAccessibile))
        ]
    }
    
    var bus : [LineInfo] {
        [
            LineInfo(name: "z601", branches: "Legnano - Rho - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z602", branches: "Legnano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z603", branches: "Vittore Olona / Nerviano - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z6C3", branches: "Vittore Olona - Cerro Maggiore - Milano Cadorna FN", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z606", branches: "Cerro Maggiore - Rho/Europa", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z611", branches: "Legnano - Canegrate - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z612", branches: "Legnano - Cerro Maggiore - Arese", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z616", branches: "Pregnana Milanese - Rho", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z617", branches: "Origgio / Lainate - Molino Dorino M1 ", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z618", branches: "Vanzago - Pogliano M. - Rho", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z619", branches: "Pogliano M. - Plesso IST Maggiolini", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z620", branches: "Magenta - Vittuone - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z621", branches: "Cuggiono - Ossona - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z622", branches: "Cuggiono - Ossona - Cornaredo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z625", branches: "Busto Arsizio - Busto Garolfo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z627", branches: "Castano Primo - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z636", branches: "Nosate - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z641", branches: "Castano Primo - Magenta", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z642", branches: "Magenta - Legnano", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z643", branches: "Vittuone - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z644", branches: "Arconate - Parabiago", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z646", branches: "Magenta - Castano Primo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z647", branches: "Cornaredo - Castano Primo", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z649", branches: "Magenta - Arluno - Molino Dorino M1", type: "Movibus", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    var net: [LineInfo] {
        [
            LineInfo(name: "z301", branches: "Milano Lampugnano M1 - Sesto FS M1 - Bergamo", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z304", branches: "Cologno Nord M2 - Brugherio", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z305", branches: "Cologno Nord M2 - Carugate - Villa Fiorita M2", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z307", branches: "Cologno Nord M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z309", branches: "Cassano D'Adda FS - Trezzo sull'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z310", branches: "Gessate M2 - Trezzo sull'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z311", branches: "Gessate M2 - Vaprio d'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z312", branches: "Gessate M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z313", branches: "Gessate M2 - Paderno D'Adda FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z314", branches: "Gessate M2 - Monza FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z315", branches: "Gorgonzola M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z317", branches: "Vimercate - Arcore FS - Correzzana", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z318", branches: "Vimercate - Carnate - Usmate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z319", branches: "Arcore FS - Vimercate - Carnate FS", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z321", branches: "Monza FS - Vimercate - Porto d’Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z322", branches: "Cologno Nord M2 - Vimercate - Porto d'Adda", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z323", branches: "Cologno Nord M2 - Vimercate", type: "NET", waitMinutes: "", stations: [], accessibilityStatus: ""),
        ]
    }
    
    var star: [LineInfo] {
        [
            LineInfo(name: "z501", branches: "Milano Famagosta - Binasco", type: "STAR Mobility", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z509", branches: "Motta Visconti - Milano Famagosta", type: "STAR Mobility", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z510", branches: "Milano Famagosta - Lacchiarella - Giussago", type: "STAR Mobility", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z515", branches: "Milano Famagosta - Zibido", type: "STAR Mobility", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z516", branches: "Milano Famagosta - Rosate - Besate", type: "STAR Mobility", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    var stav: [LineInfo] {
        [
            LineInfo(name: "z551", branches: "Abbiategrasso Vittorio Veneto - Bisceglie M1", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z552", branches: "Abbiategrasso Vittorio Veneto - S. Stefano Ticino", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z553", branches: "Abbiategrasso - Rosate - Milano Romolo", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z554", branches: "Albairate - Albairate Vermezzo FS - Bubbiano", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z555", branches: "Abbiategrasso Vittorio Veneto - Binasco / Rosate", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z556", branches: "Abbiategrasso FS - Motta Visconti", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z557", branches: "Gaggiano De Gasperi - Gaggiano FS - San Vito", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z559", branches: "Abbiategrasso Stazione FS - Magenta FS", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z560", branches: "Abbiategrasso FS - Corsico - Bisceglie M1", type: "STAV", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }

    var autoguidovie: [LineInfo] {
        [
            LineInfo(name: "z401", branches: "Melzo FS - Vignate - Villa Fiorita M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z402", branches: "Cernusco M2 - Pioltello FS - S.Felice", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z403", branches: "Gorgonzola M2 - Melzo (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z404", branches: "Melzo FS - Inzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z405", branches: "Gessate M2 - Cassano d'Adda - Treviglio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z406", branches: "Trecella FS - Bellinzago - Gessate M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z407", branches: "Gorgonzola M2 - Truccazzano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z409", branches: "Rodano - S. Felice - Linate Aereoporto", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z410", branches: "Pantigliate - Peschiera - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z411", branches: "Melzo FS - Settala - Pantigliate - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z412", branches: "Zelo B.P. - Paullo - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z413", branches: "Tribiano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z415", branches: "Melegnano - Dresano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z418", branches: "S.Zenone FS - Casalmaiocco", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z419", branches: "Paullo - Melzo - Gorgonzola M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z420", branches: "Vizzolo - Melegnano - S.Donato M3", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z431", branches: "Melegnano FS - Carpiano/Cerro L.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z432", branches: "Melegnano FS - Dresano  - Vizzolo (Circolare)", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),

            LineInfo(name: "z203", branches: "Muggiò - Monza FS - Cologno Nord M2", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z205", branches: "Limbiate Mombello - Varedo - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z209", branches: "Cesano FN - Desio - Lissone", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z219", branches: "Monza FS - Muggiò - Paderno Dugnano", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z221", branches: "Sesto S.G. - Monza FS - Carate", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z222", branches: "Monza FS - S.Fruttuoso - Sesto S.G.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z225", branches: "Sesto S.G. - Cinisello B. - Nova M.se", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z227", branches: "Monza H/Lissone FS - Muggiò - Cinisello", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z228", branches: "Seregno FS - Lissone - Monza FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z229", branches: "Paderno ITC - Cusano - Cinisello B.", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z231", branches: "Carate - Giussano - Seregno FS - Desio", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z232", branches: "Desio - Seregno - Carate - Besana FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z233", branches: "Triuggio - Albiate - Seregno FS", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z234", branches: "Vedano al L. - Lissone - Muggiò", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z242", branches: "Desio - Seregno FS - Renate", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z250", branches: "Lissone FS - Desio FS - Cesano FN", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: ""),
            LineInfo(name: "z251", branches: "Desio FS - Bovisio M. - Limbiate - Cesano FN", type: "Autoguidovie", waitMinutes: "", stations: [], accessibilityStatus: "")
        ]
    }
    
    var body: some View {
        NavigationStack{
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cerca per tipo o numero...", text: $searchInput)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 5)
            List {
                if(showRecentSearches) {
                    Section(){
                        if recentlySearchedLines.isEmpty && searchInput.isEmpty {
                            Text("Nessuna linea cercata di recente.")
                        } else {
                            if(searchInput.isEmpty) {
                                ForEach(recentlySearchedLines) { recent in
                                    if let lineInfo = fullLineInfo(for: recent.name) {
                                        LineRow(
                                            line: lineInfo.name,
                                            typeOfTransport: lineInfo.type,
                                            branches: lineInfo.branches,
                                            waitMinutes: lineInfo.waitMinutes,
                                            accessibilityStatus: lineInfo.accessibilityStatus,
                                            stations: lineInfo.stations,
                                            viewModel: viewModel
                                        )
                                    }
                                }
                            }
                        }
                    }
                    header:{
                        if(searchInput.isEmpty) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "text.magnifyingglass")
                                            .foregroundStyle(.primary)
                                        Text("Cercate di recente")
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.primary)
                                            .textCase(nil)
                                    }
                                    
                                    Text("In base alle tue ricerche")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                }
                                Spacer()
                                if(!recentlySearchedLines.isEmpty) {
                                    Button(action: {
                                        showDeletePopUp = true
                                        if(feedbacksEnabled){
                                            HapticManager.shared.trigger()
                                        }
                                    }) {
                                        Image(systemName: "delete.backward.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    if searchInput.isEmpty && shouldShowAdsAfterRecent {
                        supportLavoraMiSection
                    }
                }
                Section(){
                    if(!filteredMetros.isEmpty){
                        ForEach(filteredMetros, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredMetros.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Metropolitane")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("ATM")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://giromilano.atm.it/assets/images/schema_rete_metro.jpg")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))

                if searchInput.isEmpty && !shouldShowAdsAfterRecent {
                    supportLavoraMiSection
                }

                Section(){
                    if(!filteredSuburban.isEmpty){
                        ForEach(filteredSuburban, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredSuburban.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Suburbane")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredRegional.isEmpty){
                        ForEach(filteredRegional, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredRegional.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Regionali")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredRegioExpress.isEmpty){
                        ForEach(filteredRegioExpress, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredRegioExpress.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Regio Express")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.trenord.it/linee-e-orari/circolazione/le-nostre-linee/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredCrossBorders.isEmpty){
                        ForEach(filteredCrossBorders, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredCrossBorders.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Transfrontaliere")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("TILO")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.tilo.ch")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredMalpensaExpress.isEmpty){
                        ForEach(filteredMalpensaExpress, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header:{
                    if(!filteredMalpensaExpress.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Malpensa Express")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Trenord")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.malpensaexpress.it")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredTrams.isEmpty){
                        ForEach(filteredTrams, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header: {
                    if(!filteredTrams.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Tranviarie")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("ATM")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredFilobus.isEmpty){
                        ForEach(filteredFilobus, id: \.id) { line in
                            LineRow(line: line.name, typeOfTransport: line.type, branches: line.branches, waitMinutes: line.waitMinutes, accessibilityStatus: line.accessibilityStatus, stations: line.stations, viewModel: viewModel, onTap: { addToRecent(line) })
                        }
                    }
                }
                header: {
                    if(!filteredFilobus.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee Filoviarie")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("ATM")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.atm.it/it/AltriServizi/Trasporto/Documents/Carta%20ATM_WEB_2025.11.pdf")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredMovibus.isEmpty){
                        ForEach(filteredMovibus, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredMovibus.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Movibus")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://movibus.it/news/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredNET.isEmpty){
                        ForEach(filteredNET, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredNET.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Nordest Trasporti (NET)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://www.nordesttrasporti.it/media/2508/linee-net_area-nord-est-provincia-mi_nov2025.jpg")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredSTAR.isEmpty){
                        ForEach(filteredSTAR, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredSTAR.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("STAR Mobility")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://starmobility.it/orari-autobus/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredSTAV.isEmpty){
                        ForEach(filteredSTAV, id: \.id){bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredSTAV.isEmpty) {
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("STAV")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://stavautolinee.it/reti-servite/")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
                Section(){
                    if(!filteredAutoguidovie.isEmpty){
                        ForEach(filteredAutoguidovie, id: \.id){ bus in
                            LineRow(line: bus.name, typeOfTransport: bus.type, branches: bus.branches, waitMinutes: bus.waitMinutes, accessibilityStatus: bus.accessibilityStatus, stations: bus.stations, viewModel: viewModel, onTap: { addToRecent(bus) })
                        }
                    }
                }
                header: {
                    if(!filteredAutoguidovie.isEmpty) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linee di Bus")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                Text("Autoguidovie")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                            .padding(.bottom, 4)
                            Spacer()
                            Button(action: {
                                let url = URL(string: "https://autoguidovie.it/it/avvisi")!
                                if howToOpenLinks == .inApp {
                                    selectedURL = url
                                } else {
                                    openURLAction(url)
                                }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle("Linee")
            .scrollContentBackground(.hidden)
            .overlay {
                let allFiltered = [filteredMetros, filteredSuburban, filteredRegioExpress, filteredRegional, filteredCrossBorders, filteredMalpensaExpress, filteredTrams, filteredFilobus, filteredMovibus, filteredNET, filteredSTAV, filteredSTAR, filteredAutoguidovie]
                if allFiltered.allSatisfy({ $0.isEmpty }) {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                        VStack(spacing: 8) {
                            Text("Nessuna linea trovata per: \"\(searchInput)\"")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            Text("Prova a cercarne un' altra, come: \(generateRandomLine()).")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerRelativeFrame(.vertical)
                }
            }
            .alert("Sei sicuro?", isPresented: $showDeletePopUp) {
                Button("Annulla", role: .cancel){showDeletePopUp = false}
                Button("Continua"){recentlySearchedLinesData = Data()}
            } message: {
                Text("Sei sicuro di voler cancellare le ricerche recenti?")
            }
            .onAppear {
                requestLinesAdsIfNeeded()
            }
            .onChange(of: consentManager.isReady) { _, ready in
                if ready {
                    requestLinesAdsIfNeeded()
                }
            }
        }
    }
}

func generateRandomLine() -> String {
    /// This is a method to generate random line names for suggestions.
    /// - Parameters: no parameters for this function.
    /// - Returns: String name of the line extracted randomly.
    
    let lineList: [String] = ["M1", "M4", "S5", "S6", "S8", "R16", "R22", "R40", "RE1", "RE3", "z620", "z643"]
    let randomIndex = Int(arc4random_uniform(UInt32(lineList.count)))
    
    return lineList[randomIndex]
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

func getCurrentWorks(line: String, viewModel: WorkViewModel) -> [WorkItem]{
    return viewModel.items.filter{$0.lines.contains(line)}
}

func getLineDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.linesDeviated.firstIndex(of: line) {
        return URL(string: viewModel.linesDeviatedLink[i])!
    }
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getSuburbanDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.suburbanWithInterruptions.firstIndex(of: line) {
        return URL(string: viewModel.suburbanInterruptionLinks[i])!
    }
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getRegionalDeviationLink(line: String, viewModel: WorkViewModel) -> URL {
    if let i = viewModel.regionalWithInterruptions.firstIndex(of: line) {
        return URL(string: viewModel.regionalInterruptionLinks[i])!
    }
    
    return URL(string: "https://www.lavorami.it/404")!
}

func getInterchanges(line: String) -> [InterchangeInfo] {
    if line.starts(with: "M") && !line.starts(with: "MXP") {
        return InterchangesDB.getMetroInterchanges(line: line)
    }
    else if line.starts(with: "MXP") {
        return InterchangesDB.getMalpensaExpressInterchanges(line: line)
    }
    else if line.starts(with: "S") && !isLineTILO(lineName: line) {
        return InterchangesDB.getSuburbanInterchanges(line: line)
    }
    else if line.starts(with: "R") && !line.starts(with: "RE") {
        return InterchangesDB.getRLinesInterchanges(line: line)
    }
    else if line.starts(with: "RE") {
        return InterchangesDB.getRELinesInterchanges(line: line)
    }
    else if isLineTILO(lineName: line) {
        return InterchangesDB.getTILOInterchanges (line: line)
    }
    else if Int(line) != nil {
        if(line.wholeMatch(of: /9[0-3]/) != nil) { return InterchangesDB.getFilobusInterchanges(line: line) }
        return InterchangesDB.interchangesTrams.filter { $0.lines.contains(line) }
    }
    else {return []}
}

struct LineDetailView: View {
    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String
    
    let workScheduled: Int
    let workNow: Int
    let viewModel: WorkViewModel
    
    let stations: [MetroStation]
    let accessibilityStatus: String
    
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("alreadySeenPopUp") var alreadySeenPopUp: Bool = false
    @AppStorage("alreadySeenPopUpLines") var alreadySeenPopUpLines: Bool = false
    @AppStorage("seenPopUpCreateAccount") var seenPopUpCreateAccount: Bool = false
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @StateObject private var networkManager = NetworkMonitor()
    @StateObject private var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var showErrorDBSavePopUp: Bool = false
    
    private enum LineDetailTab { case map, works, interchanges }
    @State private var selectedTab: LineDetailTab = .map
    @State private var openPopUpWidget: Bool = false
    @State private var openPopUpLines: Bool = false
    @State private var openInfoAccessibility: Bool = false
    @State private var openInfoBusOperation: Bool = false
    @State private var openInfoLineSuspended: Bool = false
    @State private var openPopUpInfoStatus: Bool = false
    @State private var selectedBranch: String? = nil
    @State private var tramLinesSupported: [String] = ["1", "2", "3", "4", "5", "7", "9", "10", "14", "15", "16", "19", "24", "27", "31", "33"]
    @State private var linesWithBlackText: [String] = ["M3", "M5", "S5", "S6", "S8", "S11", "S12"]
    @State private var showPopUpAccount: Bool = false
    
    var activeStations: [MetroStation] {stations.filter { !$0.branch.lowercased().contains("- new") }}
    private var centerIndex: Int {max(0, activeStations.count / 2)}
    private var centerCoordinate: CLLocationCoordinate2D {
        stations.isEmpty ? CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927) : activeStations[centerIndex].coordinate
    }
    
    private var lombardyBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.46443, longitude: 9.18927),
                span: MKCoordinateSpan(latitudeDelta: 1.9, longitudeDelta: 3.2)
            ),
            minimumDistance: 1000,
            maximumDistance: 175000
        )
    }
    
    private func isStationClosed(_ stationName: String) -> Bool {
        viewModel.stazioniChiuse.contains { entry in
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return false }
            let entryName = parts[0].trimmingCharacters(in: .whitespaces)
            let entryLine = parts[1].trimmingCharacters(in: .whitespaces)
            return entryName.caseInsensitiveCompare(stationName) == .orderedSame
                && entryLine.caseInsensitiveCompare(lineName) == .orderedSame
        }
    }
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var onAppear: (() -> Void)? = nil

    private var mainStations: [MetroStation] {
        stations.filter { $0.branch == "Main" }
    }
    
    @State private var branchData: [(coords: [CLLocationCoordinate2D], isPlanned: Bool)] = []
    
    private var metroLineIndex: Int? {
        switch lineName {
            case "M1": return 0
            case "M2": return 1
            case "M3": return 2
            case "M4": return 3
            case "M5": return 4
            default: return nil
        }
    }
    
    private var metroStatusInfo: (text: String, color: Color, icon: String)? {
        guard let index = metroLineIndex,viewModel.orariChiusura.indices.contains(index),viewModel.orariApertura.indices.contains(index), viewModel.orariAperturaFestivi.indices.contains(index), viewModel.metroStatus.indices.contains(index) else { return nil }
        
        let closingTime = viewModel.orariChiusura[index]
        let openingTime = isGiornoFestivo() ? viewModel.orariAperturaFestivi[index] : viewModel.orariApertura[index]
        
        let status = isMetroChiusaOra(closingTime: closingTime, openingTime: openingTime) ? "Chiusa" : viewModel.metroStatus[index]
        
        switch status {
            case "Regolare":
                return (String(localized: .statoMetroRegolare), getColor(for: "M2"), "checkmark")
            case "Tratta Sospesa":
                return (String(localized: .statoMetroTrattaSospesa), .red, "exclamationmark.triangle.fill")
            case "Fermata Sospesa":
                return (String(localized: .statoMetroFermataSospesa), Color(red: 237/255, green: 156/255, blue: 26/255), "exclamationmark.triangle.fill")
            case "Fermate Sospese":
                return (String(localized: .statoMetroFermateSospese), Color(red: 237/255, green: 156/255, blue: 26/255), "exclamationmark.triangle.fill")
            case "Rallentata":
            return (String(localized: .statoMetroRallentata), Color(red: 237/255, green: 156/255, blue: 26/255), "clock.badge.exclamationmark.fill")
            case "Interrotta":
                return (String(localized: .statoMetroInterrotta), .red, "xmark.circle.fill")
            case "Chiusa":
                return (String(localized: .statoMetroChiusa), getColor(for: "S12"), "moon.fill")
            default:
                return nil
        }
    }
    
    private func isGiornoFestivo() -> Bool {
        Calendar.current.component(.weekday, from: Date()) == 1
    }
    
    private func isMetroChiusaOra(closingTime: String, openingTime: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "it_IT")
        
        guard let parsedClosing = formatter.date(from: closingTime),
              let parsedOpening = formatter.date(from: openingTime) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        func todayTime(from date: Date) -> Date {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: now) ?? now
        }
        
        let closing = todayTime(from: parsedClosing)
        let opening = todayTime(from: parsedOpening)
        
        let isAfterOrEqualClosing = now >= closing
        let isBeforeOpening = now < opening
        
        if closing < opening {return isAfterOrEqualClosing && isBeforeOpening}
        else {return isAfterOrEqualClosing || isBeforeOpening}
    }

    private func computeBranchData() -> [(coords: [CLLocationCoordinate2D], isPlanned: Bool)] {
        let branchGroups = Dictionary(grouping: stations.filter { $0.branch != "Main" }, by: \.branch)
        return branchGroups.compactMap { branchName, branchStations -> (coords: [CLLocationCoordinate2D], isPlanned: Bool)? in
            guard !branchStations.isEmpty else { return nil }

            let isPlanned = branchName.lowercased().contains("new") || branchName.lowercased().contains("nuova")
            let searchPool = isPlanned ? stations.filter { $0.branch != branchName } : mainStations
            guard !searchPool.isEmpty else { return nil }

            func minDist(_ s: MetroStation) -> CLLocationDistance {
                let loc = CLLocation(latitude: s.coordinate.latitude, longitude: s.coordinate.longitude)
                return searchPool.map {
                    CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: loc)
                }.min() ?? .infinity
            }

            let firstDist = minDist(branchStations.first!)
            let lastDist = minDist(branchStations.last!)
            let oriented = firstDist <= lastDist ? branchStations : branchStations.reversed()

            let junctionLoc = CLLocation(latitude: oriented.first!.coordinate.latitude, longitude: oriented.first!.coordinate.longitude)
            guard let junction = searchPool.min(by: { a, b in
                CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude).distance(from: junctionLoc)
                < CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude).distance(from: junctionLoc)
            }) else {
                return nil
            }

            return ([junction.coordinate] + oriented.map(\.coordinate), isPlanned)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                tabBarSection
                
                switch selectedTab {
                    case .map:
                        mapTabContent
                    case .works:
                        worksTabContent
                    case .interchanges:
                        interchangesTabContent
                }
            }
            .padding(.top, -20)
            .onAppear {
                onAppear?()
            }
            .sheet(isPresented: $openInfoAccessibility) {
                InfoAccessibilityView(showInfoView: $openInfoAccessibility)
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea(.all)
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio. Controlla la tua connessione ad Internet.")
            }
            .alert("Salva le tue linee", isPresented: $showPopUpAccount) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Lo sapevi che, creando un Account LavoraMi, puoi salvare le tue linee preferite per ritrovarle su tutti i tuoi dispositivi? Che aspetti! Crea un Account!")
            }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension LineDetailView {
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                if(lineName.contains("S") || (lineName == "MXP1" || lineName == "MXP2") || lineName == "RE80" || lineName.contains("RE")) {
                    Text((lineName.contains("MXP")) ? "MXP" : lineName)
                        .foregroundStyle(.white)
                        .font(.custom("TitilliumWeb-Bold", size: 40))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                else if (lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")){
                    Text(lineName)
                        .foregroundStyle(.white)
                        .font(.custom("HelveticaNeue-Bold", size: 40))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                else {
                    Text(lineName)
                        .foregroundStyle(.white)
                        .font(.system(size: 40, weight: .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                        )
                }
                
                if(lineName.contains("RE")){
                    Text("\(typeOfTransport)")
                        .font(.custom("TitilliumWeb-Bold", size: 30))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                else if(lineName == "MXP1" || lineName == "MXP2"){
                    Text("Malpensa Express")
                        .font(.custom("TitilliumWeb-Bold", size: 30))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                else {
                    if(lineName.contains("S") || (lineName == "MXP1" || lineName == "MXP2") || lineName == "RE80" || lineName.contains("RE")){
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.custom("TitilliumWeb-Bold", size: 40))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else if(lineName.contains("M") && (lineName != "MXP1" || lineName != "MXP2")){
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.custom("HelveticaNeue-Bold", size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    else{
                        Text("\(typeOfTransport) \(lineName)")
                            .font(.system(size: 30))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: {
                    if(selectedWidgetLine == lineName) {
                        selectedWidgetLine = ""
                        DataManager.shared.deleteSavedLine()
                    }
                    else {
                        DataManager.shared.setSavedLine(SavedLine(id: lineName, name: lineName, longName: typeOfTransport, iconTransport: getCurrentTransportIcon(for: typeOfTransport), worksNow: workNow, worksScheduled: workScheduled))
                        selectedWidgetLine = lineName
                        
                        if(!alreadySeenPopUp){
                            alreadySeenPopUp = true
                            openPopUpWidget = true
                        }
                    }
                }){
                    if #available(iOS 18, *){
                        Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                    else{
                        Image(systemName: (selectedWidgetLine == lineName) ? "app.badge.checkmark" : "plus.viewfinder")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                }
                .alert("Linea attivata", isPresented: $openPopUpWidget) {
                    Button("OK", role: .cancel){}
                } message: {
                    Text("Linea impostata per essere vista sul Widget dell'app!")
                }
                Button(action: {
                    if(linesSelected.contains(lineName)) {
                        linesSelected.removeAll { $0 == lineName }
                    }
                    else {
                        if(!alreadySeenPopUpLines){
                            alreadySeenPopUpLines = true
                            openPopUpLines = true
                        }
                        
                        linesSelected.append(lineName)
                    }
                    
                    if(authManager.isLoggedIn()) {
                        Task {
                            let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()
                            
                            if(preferences.enable_your_lines) {
                                let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                showErrorDBSavePopUp = !res
                            }
                        }
                    }
                    else if (!seenPopUpCreateAccount){
                        seenPopUpCreateAccount = true
                        showPopUpAccount = true
                    }
                }){
                    Image(systemName: (linesSelected.contains(lineName)) ? "heart.fill" : "heart")
                        .foregroundStyle((linesSelected.contains(lineName)) ? Color(red: 1, green: 93 / 255, blue: 162 / 255) : .gray)
                        .scaleEffect(1.5)
                }
                .padding(.leading, 10)
                .alert("Linea salvata", isPresented: $openPopUpLines) {
                    Button("OK", role: .cancel){}
                } message: {
                    Text("La linea \(lineName) è stata aggiunta nella sezione \"Le tue linee\"!")
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("DIREZIONI:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .bold()
                
                Text(branches)
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                
                if(viewModel.suburbanWithInterruptions.contains(lineName)){
                    WarningBanner(
                        text: String(localized: .interruzioniGeneraleLavori),
                        action: {
                            let url = getSuburbanDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
                if(viewModel.regionalWithInterruptions.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .interruzioniGeneraleLavori),
                        action: {
                            let url = getRegionalDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
                if(viewModel.lineeSostituiteBus.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineSubWithBus),
                        action: {
                            openInfoBusOperation = true
                        }
                    )
                }
                if(viewModel.lineeSospeseInteramente.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineSuspendedUppercased),
                        action: {
                            openInfoLineSuspended = true
                        }
                    )
                }
                if(viewModel.linesDeviated.contains(lineName)){
                    WarningBanner(
                        text: String(localized: .tramDeviations),
                        action: {
                            let url = getLineDeviationLink(line: lineName, viewModel: viewModel)
                            
                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
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
                    Text("LA LINEA È ATTIVA SOLO NEI GIORNI LAVORATIVI")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .bold()
                }
            }
            
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if(workNow != 1) {
                            Text("\(workNow) attuali,")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        else {
                            Text("\(workNow) attuale,")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        if(workScheduled != 1) {
                            Text("\(workScheduled) programmati.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        else {
                            Text("\(workScheduled) programmato.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Divider()
                    .frame(height: 36)
                HStack(spacing: 6) {
                    Image(systemName: "figure.roll")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    Image(systemName: accessibilityStatus == String(localized: .lineaAccessibile) ? "checkmark.circle.fill" : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? "exclamationmark.circle.fill" : "xmark.circle.fill"))
                        .font(.system(size: 18))
                        .foregroundColor(accessibilityStatus == String(localized: .lineaAccessibile) ? .green : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? .yellow : .red))
                    Text(accessibilityStatus)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Button(action: {
                        openInfoAccessibility = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 3)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.top, 10)
        .background(Color(uiColor: .systemBackground))
        .alert("Linea sostituita da Bus", isPresented: $openInfoBusOperation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Questa linea è attualmente sostituita interamente da Autobus e non c'è alcun treno a servire questa tratta. Il servizio è comunque garantito tra tutte le stazioni della linea.")
        }
        .alert("Linea Interamente Sospesa", isPresented: $openInfoLineSuspended) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Questa linea è stata interrotta per tutto il suo tragitto per via di lavori sulla tratta o rimodulazioni di orario. Per saperne di più, vai nella sezione \"Lavori\" della linea.")
        }
    }
    
    @ViewBuilder
    private var tabBarSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                if feedbacksEnabled { HapticManager.shared.trigger() }
                withAnimation(.snappy) { selectedTab = .map }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                    
                    if selectedTab == .map {
                        Text("Mappa")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: selectedTab == .map ? .infinity : 70)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(selectedTab == .map ? ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)) : ((lineName == "S12" && colorScheme == .dark) ? Color.white.opacity(0.15) : getColor(for: lineName).opacity(0.15)))
                )
                .foregroundStyle(selectedTab == .map ? ((!linesWithBlackText.contains(lineName)) ? .white : Color(.systemBackground)) : ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)))
            }
            Button(action: {
                if feedbacksEnabled { HapticManager.shared.trigger() }
                withAnimation(.snappy) { selectedTab = .works }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                    
                    if selectedTab == .works {
                        Text("Lavori")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: selectedTab == .works ? .infinity : 70)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(selectedTab == .works ? ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)) : ((lineName == "S12" && colorScheme == .dark) ? Color.white.opacity(0.15) : getColor(for: lineName).opacity(0.15)))
                )
                .foregroundStyle(selectedTab == .works ? ((!linesWithBlackText.contains(lineName)) ? .white : Color(.systemBackground)) : ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)))
            }
            Button(action: {
                if feedbacksEnabled { HapticManager.shared.trigger() }
                withAnimation(.snappy) { selectedTab = .interchanges }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                    
                    if selectedTab == .interchanges {
                        Text("Interscambi")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: selectedTab == .interchanges ? .infinity : 70)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(selectedTab == .interchanges ? ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)) : ((lineName == "S12" && colorScheme == .dark) ? Color.white.opacity(0.15) : getColor(for: lineName).opacity(0.15)))
                )
                .foregroundStyle(selectedTab == .interchanges ? ((!linesWithBlackText.contains(lineName)) ? .white : Color(.systemBackground)) : ((lineName == "S12" && colorScheme == .dark) ? .white : getColor(for: lineName)))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, -10)
    }
    
    @ViewBuilder
    private var mapTabContent: some View {
        let lineColor = getColor(for: lineName)
        VStack(spacing: 0) {
            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: centerCoordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: (tramLinesSupported.contains(lineName) || typeOfTransport.contains(String(localized: .filobus))) ? 0.02 : ((lineName.starts(with: "M")) ? 0.045 : 0.14),
                            longitudeDelta: (tramLinesSupported.contains(lineName) || typeOfTransport.contains(String(localized: .filobus))) ? 0.02 : ((lineName.starts(with: "M")) ? 0.045 : 0.145)
                        )
                    )
                ),
                bounds: lombardyBounds,
                content: {
                    UserAnnotation()

                    MapPolyline(coordinates: mainStations.map(\.coordinate))
                        .stroke(lineColor, lineWidth: 5)

                    ForEach(branchData.indices, id: \.self) { i in
                        if branchData[i].isPlanned {
                            MapPolyline(coordinates: branchData[i].coords)
                                .stroke(lineColor, style: StrokeStyle(lineWidth: 4, dash: [6, 6]))
                        } else {
                            MapPolyline(coordinates: branchData[i].coords)
                                .stroke(lineColor, lineWidth: 5)
                        }
                    }

                    ForEach(stations) { station in
                        if station.name == "NO_DRAW" {
                            Annotation("", coordinate: station.coordinate) {
                                EmptyView()
                            }
                        }
                        else {
                            let closed = isStationClosed(station.name)
                            
                            Annotation(station.name, coordinate: station.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(closed ? .red : .white)
                                        .frame(width: closed ? 16 : 12, height: closed ? 16 : 12)
                                    Circle()
                                        .stroke(closed ? Color.red : lineColor, lineWidth: 3)
                                        .frame(width: closed ? 16 : 12, height: closed ? 16 : 12)
                                                                            
                                    if closed {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                }
            )
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .tint(getColor(for: lineName))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                if let status = metroStatusInfo {
                    if status.text == String(localized: .statoMetroRegolare) || status.text == String(localized: .statoMetroChiusa) {
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .font(.system(size: 13, weight: .bold))
                            Text(status.text)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(status.color))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(12)
                    } else {
                        Button {
                            openPopUpInfoStatus = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: status.icon)
                                    .font(.system(size: 13, weight: .bold))
                                Text(status.text)
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(status.color))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(12)
                    }
                }
            }
        }
        .alert("Stato Attuale Metro", isPresented: $openPopUpInfoStatus) {
            Button("Chiudi", role: .cancel) {}
        } message: {
            Text(viewModel.messageCurrentStatus)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 10)
        .onAppear {
            locationManager.requestPermission()
            if branchData.isEmpty {
                branchData = computeBranchData()
            }
            if metroLineIndex != nil {
                viewModel.fetchMetroStatus()
            }
        }
    }
    
    @ViewBuilder
    private var worksTabContent: some View {
        VStack {
            ScrollView {
                let currentWorks = getCurrentWorks(line: (typeOfTransport.contains(String(localized: .filobus)) ? "Filobus \(lineName)" : lineName), viewModel: viewModel)
                if currentWorks.count > 0 {
                    LazyVStack(spacing: 12) {
                        ForEach(currentWorks) { work in
                            WorkInProgressRow(item: work)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Label {
                        Text((networkManager.isConnected) ? "Non ci sono lavori su questa linea." : "Nessuna connessione ad Internet.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: (networkManager.isConnected) ? "info.circle.fill" : "wifi.slash")
                            .foregroundStyle(.white)
                            .font(.system(size: 15))
                    }
                    .padding()
                    .bold()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private var interchangesTabContent: some View {
        let isMetro = lineName.starts(with: "M") && !lineName.starts(with: "MXP")
        let isMalpensaExpress = lineName.starts(with: "MXP")
        let isSuburban = lineName.starts(with: "S") && !isLineTILO(lineName: lineName)
        let isTilo = isLineTILO(lineName: lineName)
        let isRegional = lineName.starts(with: "R") && !lineName.starts(with: "RE")
        let isRegioExpress = lineName.starts(with: "RE")
        let isFilobus = lineName == "90" || lineName == "91" || lineName == "92" || lineName == "93"
        
        let isAvailable = (isMetro || isMalpensaExpress || isSuburban || isTilo || isRegional || isFilobus || isRegioExpress)
        
        let allInterchanges = getInterchanges(line: lineName)
        let mainItems = allInterchanges.filter { $0.branch == "Main" }
        let branchMap = Dictionary(grouping: allInterchanges.filter { $0.branch != "Main" && $0.lines.first == lineName },by: \.branch)
        let availableBranches = branchMap.keys.sorted()

        VStack(spacing: 0) {
            if isAvailable && availableBranches.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableBranches, id: \.self) { branch in
                            Button(action: {
                                selectedBranch = branch
                                HapticManager.shared.trigger()
                            }) {
                                Text(branch)
                                    .font(.system(size: 15))
                                    .foregroundStyle(selectedBranch == branch ? .white : Color("TextColor"))
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 14)
                                    .background(Capsule().fill(selectedBranch == branch ? getColor(for: lineName) : Color(.secondarySystemBackground)))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            ScrollView {
                let toShow: [InterchangeInfo] = {
                    if isAvailable {
                        let validMain = mainItems.filter { $0.lines.first == lineName }
                        let sortedMain = validMain.sorted { $1.lineOrder > $0.lineOrder }
                        
                        if let branch = selectedBranch {
                            if(branch == "Assago Milanofiori Forum" || branch == "P.Za Abbiategrasso"){
                                let validBranch = (branchMap[branch] ?? []).filter { $0.lines.first == lineName }
                                let branchItems = validBranch.sorted { $0.lineOrder > $1.lineOrder }
                                return sortedMain + branchItems
                            }
                            else {
                                let validBranch = (branchMap[branch] ?? []).filter { $0.lines.first == lineName }
                                let branchItems = validBranch.sorted { $1.lineOrder > $0.lineOrder }
                                return branchItems + sortedMain
                            }
                        }
                        else {
                            let allBranch = availableBranches.flatMap { branch in
                                (branchMap[branch] ?? [])
                                    .filter { $0.lines.first == lineName }
                                    .sorted { $1.lineOrder > $0.lineOrder }
                            }
                            return sortedMain + allBranch
                        }
                    }
                    else {
                        return allInterchanges
                    }
                }()

                if !toShow.isEmpty {
                    if isAvailable {
                        VStack(spacing: 0) {
                            ForEach(Array(toShow.enumerated()), id: \.element.id) { idx, interchange in
                                InterchangeRow(
                                    interchange: interchange,
                                    currentLine: lineName,
                                    isFirst: idx == 0,
                                    isLast: idx == toShow.count - 1
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(toShow) { interchange in
                                InterchangeView(item: interchange, currentLine: lineName)
                            }
                        }
                    .padding(.vertical, 8)
                    }
                } else {
                    Text("Nessun interscambio con questa linea.")
                        .padding()
                        .bold()
                        .font(.system(size: 15))
                }
            }
        }
        .onAppear(){
            if selectedBranch == nil, let first = availableBranches.first {
                selectedBranch = first
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.bottom, 10)
        .padding(.top, 6)
    }
}

struct WarningBanner: View {
    let text: String
    let action: () -> Void
    
    private let amberColor = Color.init(red: 1.0, green: 0.6, blue: 0.0)
    private let backgroundColor = Color.init(red: 1.0, green: 0.8, blue: 0.4).opacity(0.2)
    
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(amberColor)
            
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(amberColor)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(amberColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

struct LineSmallDetailedView: View {
    @AppStorage("selectedWidgetLine") private var selectedWidgetLine: String = ""
    @AppStorage("feedbacksEnabled") var feedbacksEnabled: Bool = true
    @AppStorage("alreadySeenPopUp") var alreadySeenPopUp: Bool = false
    @AppStorage("alreadySeenPopUpLines") var alreadySeenPopUpLines: Bool = false
    @AppStorage("seenPopUpCreateAccount") var seenPopUpCreateAccount: Bool = false
    @AppStorage("linesSelected") private var linesSelected: [String] = []
    @AppStorage("linesFavorites") private var linesFavorites: [String] = []
    @State private var openPopUpWidget: Bool = false
    @State private var openInfoAccessibility: Bool = false
    @State private var openInfoLineSuspended: Bool = false
    @StateObject private var networkManager = NetworkMonitor()
    @StateObject private var authManager = AuthManager()
    @Environment(\.openURL) private var openURLAction
    @AppStorage("linkOpenURL") var howToOpenLinks: linkOpenTypes = .inApp
    @State private var selectedURL: URL?
    @State private var showErrorDBSavePopUp: Bool = false
    @State private var showPopUpAccount: Bool = false

    let lineName: String
    let typeOfTransport: String
    let branches: String
    let waitMinutes: String

    let workScheduled: Int
    let workNow: Int
    let accessibilityStatus: String
    let viewModel: WorkViewModel
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    fileprivate enum LineSmallTab { case works, arrivi }
    @State fileprivate var selectedTab: LineSmallTab = .works

    private var cdnURL: URL? {
        let upper = lineName.uppercased()
        return URL(string: "https://cdn.lavorami.it/gtfs/\(upper).json")
    }

    @State private var routeData: GTFSRoute? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedStopId: String? = nil
    @State private var selectedStopName: String = ""
    @State private var currentTime = Date()
    @State private var isStartingAnimation = false
    @State private var opacity: Double = 1.0
    @State private var openPopUpLines: Bool = false

    let interchanges = InterchangesDB.interchangesBus

    var activeInterchange: InterchangeStation? {
        interchanges.first { station in
            station.linesToShow.contains(lineName)
        }
    }

    var onAppear: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                tabBarSection

                if selectedTab == .works {
                    VStack {
                        ScrollView {
                            let currentWorks = getCurrentWorks(line: lineName, viewModel: viewModel)
                            if currentWorks.count > 0 {
                                LazyVStack(spacing: 12) {
                                    ForEach(currentWorks) { work in
                                        WorkInProgressRow(item: WorkItem(
                                            title: work.title, titleIcon: work.titleIcon,
                                            typeOfTransport: work.typeOfTransport, roads: work.roads,
                                            lines: work.lines, startDate: work.startDate,
                                            endDate: work.endDate, details: work.details,
                                            company: work.company
                                        ))
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                Label((networkManager.isConnected) ? "Non ci sono lavori su questa linea." : "Nessuna connessione ad Internet.", systemImage: (networkManager.isConnected) ? "info.circle.fill" : "wifi.slash")
                                    .padding().bold().font(.system(size: 15))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 10)
                } else if selectedTab == .arrivi {
                    VStack(spacing: 0) {
                        if isLoading {
                            Spacer()
                            ProgressView("Caricamento orari...")
                                .controlSize(.large)
                            Spacer()
                        } else if let route = routeData {
                            VStack(spacing: 0) {
                                HStack(spacing: 10) {
                                    Image(systemName: "location.fill")
                                        .font(.title2)

                                    Menu {
                                        ForEach(sortedStops(route: route), id: \.id) { stop in
                                            Button(stop.name) {
                                                selectedStopId = stop.id
                                                selectedStopName = stop.name
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedStopId.flatMap { route.stops[$0]?.n } ?? "Scegli una fermata...")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color("TextColor"))
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))

                                Divider()
                            }
                            if let stopId = selectedStopId, let departuresByDir = GTFSHelper.getDepartures(for: stopId, in: route, limit: 3) {
                                ScrollView {
                                    VStack(spacing: 14) {
                                        ForEach(Array(departuresByDir.keys).sorted(), id: \.self) { dirId in
                                            let departures = departuresByDir[dirId] ?? []
                                            let headsign = departures.first?.headsign ?? "Direzione \(dirId)"

                                            let isLastStop = selectedStopName.caseInsensitiveCompare(headsign) == .orderedSame

                                            VStack(alignment: .leading, spacing: 0) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "arrow.forward")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)

                                                    Text(isLastStop ? "PROSSIMI ARRIVI: \(headsign)" : "DIREZIONE: \(headsign.uppercased())")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)


                                                if departures.isEmpty {
                                                    Text("Nessuna corsa prevista per oggi")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .padding(.horizontal, 16)
                                                        .padding(.bottom, 12)
                                                } else {
                                                    let first = departures[0]
                                                    let rest = Array(departures.dropFirst().prefix(3))

                                                    VStack(alignment: .leading, spacing: 12) {
                                                        HStack(alignment: .center, spacing: 10) {
                                                            Image(systemName: "clock.fill")
                                                                .foregroundStyle((first.minutesFromNow < 10) ? ((first.minutesFromNow < 5) ? ((first.minutesFromNow == 0) ? .yellow : .red) : .orange) : .green)
                                                                .font(.system(size: 18))

                                                            Text(first.minutesFromNow == 0 ? String(localized: .inPartenza) : first.formattedWait)
                                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                                .foregroundStyle((first.minutesFromNow < 10) ? ((first.minutesFromNow < 5) ? ((first.minutesFromNow == 0) ? .yellow : .red) : .orange) : .green)
                                                            Spacer()
                                                            Text(first.time)
                                                                .font(.system(size: 15, weight: .medium))
                                                                .foregroundStyle(.secondary)
                                                        }

                                                        Text("Il bus può fare un ritardo dai 3 ai 5 minuti, questo è l'orario programmato.")
                                                            .font(.system(size: 10, weight: .medium))
                                                            .foregroundStyle(.secondary)

                                                        if !rest.isEmpty {
                                                            Divider()

                                                            HStack(spacing: 16) {
                                                                ForEach(rest) { dep in
                                                                    HStack(spacing: 5) {
                                                                        Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                                                                            .font(.caption2)
                                                                            .foregroundStyle(.secondary)
                                                                        Text(dep.formattedWait)
                                                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                                            .foregroundStyle(.primary)
                                                                        Text(dep.time)
                                                                            .font(.caption2)
                                                                            .foregroundStyle(.secondary)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(16)
                                                    .background(Color(.secondarySystemBackground))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                    }
                                }

                            } else if selectedStopId != nil {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "clock.badge.questionmark.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.secondary)

                                    Text("Nessuna corsa prevista per oggi.")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.primary)
                                    Text("Per oggi non c'è nessuna corsa programmata per questa fermata, prova a sceglierne un' altra.")
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 20)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            } else {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.secondary)
                                    Text("Seleziona una fermata")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }

                        } else if let error = errorMessage {
                            Spacer()
                            ContentUnavailableView("Errore", systemImage: "exclamationmark.triangle", description: Text(error))
                            Spacer()
                        }
                    }
                    .id(currentTime)
                    .onReceive(timer) { newTime in
                        currentTime = newTime
                    }
                }
            }
            .padding(.top, -20)
            .onAppear {
                onAppear?()
            }
            .sheet(isPresented: $openInfoAccessibility) {
                InfoAccessibilityView(showInfoView: $openInfoAccessibility)
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url).ignoresSafeArea(.all)
            }
            .alert("Errore di connessione", isPresented: $showErrorDBSavePopUp) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Si è verificato un errore di connessione durante il salvataggio. Controlla la tua connessione ad Internet.")
            }
            .alert("Salva le tue linee", isPresented: $showPopUpAccount) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text("Lo sapevi che, creando un Account LavoraMi, puoi salvare le tue linee preferite per ritrovarle su tutti i tuoi dispositivi? Che aspetti! Crea un Account!")
            }
            .alert("Linea Interamente Sospesa", isPresented: $openInfoLineSuspended) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Questa linea è stata interrotta per tutto il suo tragitto per via di lavori sulla tratta o rimodulazioni di orario. Per saperne di più, vai nella sezione \"Lavori\" della linea.")
            }
            .onAppear { if routeData == nil { loadData() } }
            .navigationTitle("Dettagli Linea")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sortedStops(route: GTFSRoute) -> [(id: String, name: String)] {
        route.stops.map { ($0.key, $0.value.n) }.sorted { $0.name < $1.name }
    }

    private func loadData() {
        guard let url = cdnURL else { return }
        isLoading = true
        Task {
            do {
                let route = try await GTFSHelper.load(from: url)
                await MainActor.run {
                    self.routeData = route
                    self.isLoading = false
                    if self.selectedStopId == nil {
                        self.selectedStopId = sortedStops(route: route).first?.id
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Errore nel caricamento dati."
                    self.isLoading = false
                }
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.15).delay(1.05)) {
            opacity = 0.5
        }
        withAnimation(.easeIn(duration: 0.15).delay(1.35)) {
            opacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            startAnimation()
        }
    }
}

extension LineSmallDetailedView {
    @ViewBuilder
    fileprivate var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text(lineName)
                    .foregroundStyle(.white)
                    .font(.system(size: (typeOfTransport == String(localized: .tram)) ? 40 : 30, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((typeOfTransport == String(localized: .tram)) ? .orange : getColor(for: lineName))
                    )

                if(typeOfTransport.contains(String(localized: .tram))) {
                    Text("\(typeOfTransport) \(lineName)")
                        .font(.system(size: 30))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                else {
                    Text("\(typeOfTransport)")
                        .font(.system(size: 25))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    if selectedWidgetLine == lineName {
                        selectedWidgetLine = ""
                        DataManager.shared.deleteSavedLine()
                    } else {
                        DataManager.shared.setSavedLine(SavedLine(
                            id: lineName, name: lineName, longName: typeOfTransport,
                            iconTransport: getCurrentTransportIcon(for: typeOfTransport),
                            worksNow: workNow, worksScheduled: workScheduled
                        ))
                        selectedWidgetLine = lineName
                        if(!alreadySeenPopUp) {
                            alreadySeenPopUp = true
                            openPopUpWidget = true
                        }
                    }
                }) {
                    if #available(iOS 18, *){
                        Image(systemName: (selectedWidgetLine == lineName) ? "widget.small" : "widget.small.badge.plus")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                    else{
                        Image(systemName: (selectedWidgetLine == lineName) ? "app.badge.checkmark" : "plus.viewfinder")
                            .foregroundStyle((selectedWidgetLine == lineName) ? .yellow : .gray)
                            .scaleEffect(1.5)
                    }
                }
                .alert("Linea attivata", isPresented: $openPopUpWidget) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Linea impostata per essere vista sul Widget dell'app!")
                }
                Button(action: {
                    if(linesSelected.contains(lineName)) {
                        linesSelected.removeAll { $0 == lineName }
                    }
                    else {
                        if(!alreadySeenPopUpLines){
                            alreadySeenPopUpLines = true
                            openPopUpLines = true
                        }

                        linesSelected.append(lineName)
                    }

                    if(authManager.isLoggedIn()) {
                        Task {
                            let preferences: UserPreferencesDatas = await authManager.fetchUserPreferences()

                            if(preferences.enable_your_lines) {
                                let res = await authManager.saveDatasToDb(favorites: linesFavorites, yourLines: linesSelected)
                                showErrorDBSavePopUp = !res
                            }
                        }
                    }
                    else if (!seenPopUpCreateAccount){
                        seenPopUpCreateAccount = true
                        showPopUpAccount = true
                    }
                }){
                    Image(systemName: (linesSelected.contains(lineName)) ? "heart.fill" : "heart")
                        .foregroundStyle((linesSelected.contains(lineName)) ? Color(red: 1, green: 93 / 255, blue: 162 / 255) : .gray)
                        .scaleEffect(1.5)
                }
                .padding(.leading, 10)
                .alert("Linea salvata", isPresented: $openPopUpLines) {
                    Button("OK", role: .cancel){}
                } message: {
                    Text("La linea \(lineName) è stata aggiunta nella sezione \"Le tue linee\"!")
                }
            }

            if !accessibilityStatus.isEmpty {
                HStack {
                    Image(systemName: "figure.roll")
                        .foregroundStyle(.gray)
                        .scaleEffect(1.5)
                    Image(systemName: accessibilityStatus == String(localized: .lineaAccessibile)
                        ? "checkmark.circle.fill"
                        : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile)
                            ? "exclamationmark.circle.fill"
                            : "xmark.circle.fill"))
                        .foregroundStyle(accessibilityStatus == String(localized: .lineaAccessibile)
                            ? .green
                            : (accessibilityStatus == String(localized: .lineaParzialmenteAccessibile) ? .yellow : .red))
                        .scaleEffect(1.5)
                        .padding(.leading, 5)
                    Text(accessibilityStatus)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                    Spacer()
                    Button(action: { openInfoAccessibility = true }) {
                        Image(systemName: "info.circle.fill").foregroundColor(.gray)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("DIREZIONI:")
                    .font(.caption).foregroundStyle(.secondary).bold()
                Text(branches)
                    .font(.title3).multilineTextAlignment(.leading)

                if viewModel.linesDeviated.contains(lineName) {
                    WarningBanner(
                        text: String(localized: .tramDeviations),
                        action: {
                            let url = getLineDeviationLink(line: lineName, viewModel: viewModel)

                            if(howToOpenLinks == .inApp) {
                                selectedURL = url
                            }
                            else {
                                openURLAction(url)
                            }
                        }
                    )
                }
                if(viewModel.lineeSospeseInteramente.contains(lineName)) {
                    WarningBanner(
                        text: String(localized: .lineSuspendedUppercased),
                        action: {
                            openInfoLineSuspended = true
                        }
                    )
                }
            }

            if !waitMinutes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TEMPO DI ATTESA MEDIO:")
                        .font(.caption).foregroundStyle(.secondary).bold()
                    Text(waitMinutes)
                        .font(.title3).multilineTextAlignment(.leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FERMATA DI INTERSCAMBIO:")
                        .font(.caption).foregroundStyle(.secondary).bold()
                    if let station = activeInterchange {
                        Label(station.displayName, systemImage: station.typeOfInterchange)
                            .font(.title3).multilineTextAlignment(.leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(station.lines, id: \.self) { line in
                                    TransportBadge(line: line)
                                }
                            }
                        }
                    } else {
                        Text("Nessuna fermata di interscambio.").foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 0) {
                    if(workNow != 1) {
                        Text("\(workNow) attuali,")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    else {
                        Text("\(workNow) attuale,")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if(workScheduled != 1) {
                        Text("\(workScheduled) programmati.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    else {
                        Text("\(workScheduled) programmato.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    fileprivate var tabBarSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                if feedbacksEnabled { HapticManager.shared.trigger() }
                withAnimation(.snappy) { selectedTab = .works }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)

                    if selectedTab == .works {
                        Text("Lavori")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: selectedTab == .works ? .infinity : 70)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(selectedTab == .works ? getColor(for: lineName) : getColor(for: lineName).opacity(0.15))
                )
                .foregroundStyle(selectedTab == .works ? .white : getColor(for: lineName))
            }
            if viewModel.linesSupportedGTFS.contains(lineName) {
                Button(action: {
                    if feedbacksEnabled { HapticManager.shared.trigger() }
                    withAnimation(.snappy) { selectedTab = .arrivi }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.title3)

                        if selectedTab == .arrivi {
                            Text("Arrivi")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: selectedTab == .arrivi ? .infinity : 70)
                    .frame(height: 38)
                    .background(
                        Capsule()
                            .fill(selectedTab == .arrivi ? getColor(for: lineName) : getColor(for: lineName).opacity(0.15))
                    )
                    .foregroundStyle(selectedTab == .arrivi ? .white : getColor(for: lineName))
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct InfoAccessibilityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @Binding var showInfoView: Bool
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if #available(iOS 18.0, *), enableAnimations {
                        Image(systemName: startImageTransition ? "figure.roll" : "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 50)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        startImageTransition = true
                                    }
                                }
                            }
                            .onDisappear {
                                startImageTransition = false
                            }
                    } else {
                        Image(systemName: "figure.roll")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 40)
                    }

                    Text("Informazioni sull'Accessibilità")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("LavoraMi mostra l'accessibilità di una linea in base agli impianti nelle stazioni e alla tipologia di mezzo utilizzato.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("LavoraMi prende queste informazioni da fonti autorevoli e affidabili, i dati potrebbero non essere aggiornati all'ultimo minuto.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 20) {
                        accessibilitySection(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            title: String(localized: .completamenteAccessibile),
                            description: String(localized: .completamenteAccessibileDeps)
                        )
                        Divider()
                        accessibilitySection(
                            icon: "exclamationmark.circle.fill",
                            color: .orange,
                            title: String(localized: .parzialmenteAccessibile),
                            description: String(localized: .parzialmenteAccessibileDeps)
                        )
                        Divider()
                        accessibilitySection(
                            icon: "xmark.circle.fill",
                            color: .red,
                            title: String(localized: .nonAccessibile),
                            description: String(localized: .nonAccessibileDeps)
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Accessibilità")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        showInfoView = false
        presentationMode.wrappedValue.dismiss()
    }

    @ViewBuilder
    private func accessibilitySection(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.roll")
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

struct DetailSetYourLineView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    @State var startImageTransition: Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @Binding var showInfoView: Bool
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ScrollView {
                        VStack(spacing: 30) {
                            if #available(iOS 18.0, *), enableAnimations {
                                Image(systemName: startImageTransition ? "heart.fill" : "plus.app.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 50)
                                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                    .onAppear {
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            withAnimation {
                                                startImageTransition = true
                                            }
                                        }
                                    }
                                    .onDisappear {
                                        startImageTransition = false
                                    }
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 40)
                            }

                            Text("Come posso mettere una linea nei preferiti?")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            (Text("Per poter mettere la TUA linea tra i preferiti, basta che vai nella sezione \"Linee\" con questo simbolo: ")
                             + Text(Image(systemName: "arrow.branch")))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Per aggiungere una linea in questa sezione, vai nella scheda della tua ")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text("linea").bold()
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text(", clicca su ")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text(Image(systemName: "heart"))
                            + Text(" per aggiungerla alla lista. Puoi modificarla in qualsiasi momento.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Divider()
                            
                            Text("Scegli qualsiasi linea.")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            HStack{
                                Text("M1")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "M1"))
                                    )
                                
                                Text("S5")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "S5"))
                                    )
                                
                                Text("M3")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "M3"))
                                    )
                                
                                Text("S2")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "S2"))
                                    )
                                
                                Text("z620")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "z620"))
                                    )
                            }
                            
                            Text("Non importa se Suburbano, Metro o Bus, scegli la linea che più ti interessa.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .tag(0)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Linee Preferite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        showInfoView = false
        presentationMode.wrappedValue.dismiss()
    }
    
    @ViewBuilder
    private func currentStatus(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.branch")
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

struct LineDeviationInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var startImageTransition: Bool = false
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if #available(iOS 18.0, *), enableAnimations {
                        Image(systemName: startImageTransition ? "arrow.trianglehead.pull" : "arrow.trianglehead.branch")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 50)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(for: .seconds(1))
                                    withAnimation {
                                        startImageTransition = true
                                    }
                                }
                            }
                            .onDisappear {
                                startImageTransition = false
                            }
                    } else {
                        Image(systemName: "arrow.branch")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 40)
                    }

                    Text("Informazioni sulle mappe")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("LavoraMi potrebbe non mostrare il percorso attuale delle linee sulle mappe, poiché sono in corso deviazioni, interruzioni di tratte del percorso o di stazioni non accessibili. Consultate gli avvisi nella sezione \"Lavori\"!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("LavoraMi prende queste informazioni da fonti autorevoli e affidabili, le eventuali deviazioni di percorso sono indicate nei lavori qui sotto mostrati, potete prendere le eventuali soluzioni di viaggio nell'apposita sezione.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        currentStatus(
                            icon: "person.crop.square.fill",
                            color: .green,
                            title: String(localized: .personaleTitle),
                            description: String(localized: .personaleDeps)
                        )
                        Divider()
                        currentStatus(
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            title: String(localized: .lavoriDeviationInfoTitle),
                            description: String(localized: .lavoriDeviationInfoDeps)
                        )
                        Divider()
                        currentStatus(
                            icon: "person.crop.circle.badge.exclamationmark",
                            color: .red,
                            title: String(localized: .incorrettezzeTitle),
                            description: String(localized: .incorrettezzeDeps)
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Info sulle Mappe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {presentationMode.wrappedValue.dismiss()}
    
    @ViewBuilder
    private func currentStatus(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

private struct BouncingMarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct BouncingMarqueeText: View {
    let text: String
    var font: Font
    var color: Color = Color("TextColor")
    var lineHeight: CGFloat
    var speed: Double = 45
    var edgePause: Double = 3
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isReady: Bool = false
    @State private var isAnimating: Bool = false

    private var scrollDistance: CGFloat { max(0, textWidth - containerWidth) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if isReady {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .fixedSize()
                        .offset(x: -offset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
            .onAppear {
                containerWidth = geo.size.width
                tryStart()
            }
            .onChange(of: geo.size.width) { _, cw in
                containerWidth = cw
                tryStart()
            }
        }
        .frame(height: lineHeight)
        .background(
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .hidden()
                .background(
                    GeometryReader { tg in
                        Color.clear.preference(
                            key: BouncingMarqueeTextWidthKey.self,
                            value: tg.size.width
                        )
                    }
                )
        )
        .onPreferenceChange(BouncingMarqueeTextWidthKey.self) { tw in
            textWidth = tw
            tryStart()
        }
        .onChange(of: text) { _, _ in
            isAnimating = false
            isReady = false
            offset = 0
            textWidth = 0
            tryStart()
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func tryStart() {
        guard textWidth > 0, containerWidth > 0, !isReady else { return }
        isReady = true
        guard scrollDistance > 1 else { return }
        isAnimating = true
        runCycle()
    }

    private func runCycle() {
        guard isAnimating else { return }
        let goDuration = scrollDistance / speed

        DispatchQueue.main.asyncAfter(deadline: .now() + edgePause) {
            guard isAnimating else { return }
            withAnimation(.linear(duration: goDuration)) {
                offset = scrollDistance
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + goDuration + edgePause) {
                guard isAnimating else { return }
                withAnimation(.linear(duration: goDuration)) {
                    offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + goDuration) {
                    runCycle()
                }
            }
        }
    }
}

struct InterchangeRow: View {
    let interchange: InterchangeInfo
    let currentLine: String
    let isFirst: Bool
    let isLast: Bool

    var lineColor: Color { getColor(for: currentLine) }
    var otherLines: [String] { interchange.lines.filter { $0 != currentLine } }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : lineColor)
                    .frame(width: 3)
                    .frame(height: 14)
                Circle()
                    .strokeBorder(lineColor, lineWidth: 3)
                    .background(Circle().fill(Color.white))
                    .frame(width: 16, height: 16)
                Rectangle()
                    .fill(isLast ? Color.clear : lineColor)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(interchange.name.uppercased())
                    .font(.custom("TitilliumWeb-Bold", size: 20))
                    .foregroundStyle(Color("TextColor"))

                if !otherLines.isEmpty {
                    HStack(spacing: 6) {
                        if interchange.typeOfInterchange == "stadium.fill" {
                            Image(interchange.typeOfInterchange)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(Color("TextColor"))
                        } else {
                            Image(systemName: interchange.typeOfInterchange)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color("TextColor"))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(otherLines, id: \.self) { line in
                                    Group {
                                        if line.contains(String(localized: .filobus)) || line.wholeMatch(of: /9[0-3]/) != nil {
                                            Label(line, systemImage: "bolt.fill")
                                        } else if line.starts(with: "N") {
                                            Label(line, systemImage: "moon.fill")
                                        } else {
                                            Text(line)
                                        }
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color("TextColor"))

                        Text("Fermata senza interscambi.")
                            .font(.custom("TitilliumWeb-Bold", size: 15))
                            .foregroundStyle(Color("TextColor"))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
}

struct InterchangeView: View {
    let item: InterchangeInfo
    let currentLine: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if(item.name == "Lodi TIBB"){
                Label("Milano Scalo Romana FS", systemImage: "arrow.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
            }
            else{
                Label(item.name, systemImage: "arrow.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("TextColor"))
            }
            
            HStack {
                Text(currentLine)
                    .font(.headline)
                Image(systemName: item.typeOfInterchange)
                Text(item.name)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(item.lines, id: \.self) { line in
                        if line.contains(String(localized: .filobus)) || line.wholeMatch(of: /9[0-3]/) != nil {
                            Label(line, systemImage: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                        } else if line.starts(with: "N") {
                            Label(line, systemImage: "moon.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                        } else {
                            Text(line)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(getColor(for: line)))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct TransportBadge: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let line: String
    
    private var badgeColor: Color {
        if line.starts(with: "z") {
            return getColor(for: "z")
        }
        return getColor(for: line)
    }

    var body: some View {
        Text(line)
            .foregroundStyle(.white)
            .font(.system(size: 20, weight: .bold))
            .padding(.vertical, 4)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(badgeColor)
            )
    }
}

//MARK: UTILITIES
//NOTE: FILTERS
enum FilterBy: String, CaseIterable, Identifiable {
    case suggested = "Le tue linee"
    case all = "Tutti"
    case bus = "Bus"
    case tram = "Tram"
    case metro = "Metropolitana"
    case train = "Treno"
    case working = "In Corso"
    case scheduled = "Programmati"
    case ATM = "di ATM"
    case Trenord = "di Trenord"
    case Tilo = "di TILO"
    case Movibus = "di Movibus"
    case Net = "di NET"
    case STAV = "di STAV"
    case STAR = "di STAR"
    case Autoguidovie = "di Autoguidovie"
    
    var localizedTitle: String {
        switch self {
            case .suggested: return String(localized: .yourLinesChip)
            case .all: return String(localized: .tutti)
            case .bus: return String(localized: .bus)
            case .tram: return String(localized: .tram)
            case .metro : return String(localized: .metropolitana)
            case .train: return String(localized: .treno)
            case .working: return String(localized: .inCorso)
            case .scheduled: return String(localized: .programmati)
            case .ATM: return String(localized: .diAtm)
            case .Trenord: return String(localized: .diTrenord)
            case .Tilo: return String(localized: .diTilo)
            case .Movibus: return String(localized: .diMovibus)
            case .Net: return String(localized: .diNET)
            case .STAV: return String(localized: .diStav)
            case .STAR: return String(localized: .diStar)
            case .Autoguidovie: return String(localized: .diAutoguidovie)
        }
    }
    
    var id: String{self.rawValue}
}

enum AppearanceType: Int, CaseIterable, Identifiable {
    case system = 0
    case dark = 1
    case light = 2
    
    var description: String {
        switch self {
            case .system: return String(localized: .sistema)
            case .light: return String(localized: .chiaro)
            case .dark: return String(localized: .scuro)
        }
    }
    
    var iconName: String {
        switch self {
            case .system: return "gear"
            case .dark: return "moon.fill"
            case .light: return "sun.max.fill"
        }
    }
    
    var id: Int{self.rawValue}
}

struct LineInfo: Identifiable{
    let id = UUID()
    let name: String
    let branches: String
    let type: String
    let waitMinutes: String
    let stations: [MetroStation]
    let accessibilityStatus: String
}

struct LineShortInfo: Identifiable{
    let id = UUID()
    let name: String
}

struct InterchangeInfo: Identifiable {
    let id = UUID()
    let name: String
    let lines: [String]
    let typeOfInterchange: String
    let branch: String
    let lineOrder: Int

    init(name: String, lines: [String], typeOfInterchange: String, branch: String = "Main", lineOrder: Int = 0) {
        self.name = name
        self.lines = lines
        self.typeOfInterchange = typeOfInterchange
        self.branch = branch
        self.lineOrder = lineOrder
    }
}

struct MetroStation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let branch: String
}

struct InterchangeStation: Identifiable {
    let id = UUID()
    let displayName: String
    let lines: [String]
    let typeOfInterchange: String
    let linesToShow: [String]
}

enum linkOpenTypes: String, CaseIterable, Identifiable{
    case inApp = "In App"
    case safari = "Safari"
    
    var id: String{self.rawValue}
    var localizedID: String {
        switch self {
            case .inApp: return String(localized: .inAppLocalized)
            case .safari: return "Safari"
        }
    }
}

enum fileFormatType: String, CaseIterable, Identifiable{
    case json = "Json"
    case html = "HTML"
    
    var id: String{self.rawValue}
}

func getColor(for line: String) -> Color {
    switch line {
        ///SUBURBAN LINES
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
        case "S12": return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 35/255, alpha: 1) : .black
        })
        case "S13": return Color(red: 167/255, green: 109/255, blue: 17/255)
        case "S19": return Color(red: 102/255, green: 13/255, blue: 54/255)
        case "S31": return .gray
        
        ///TILO LINES
        case "S10": return Color(red: 228/255, green: 35/255, blue: 19/255)
        case "S20": return Color(red: 25/255, green: 57/255, blue: 105/255)
        case "S30": return Color(red: 0, green: 166/255, blue: 81/255)
        case "S40": return Color(red: 117/255, green: 188/255, blue: 118/255)
        case "S50": return Color(red: 131/255, green: 76/255, blue: 22/255)
        case "S90": return Color(red: 231/255, green: 197/255, blue: 61/255)
        case "RE80": return .blue
        
        ///METRO LINES
        case "M1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "NM1": return Color(red: 228/255, green: 5/255, blue: 32/255)
        case "M2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "NM2": return Color(red: 95/255, green: 147/255, blue: 34/255)
        case "M3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "NM3": return Color(red: 252/255, green: 190/255, blue: 0)
        case "M4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "NM4": return Color(red: 0, green: 22/255, blue: 137/255)
        case "M5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        case "NM5": return Color(red: 165/255, green: 147/255, blue: 198/255)
        
        ///BUS LINES
        case _ where line.contains("z"): return Color(red: 28/255, green: 28/255, blue: 1)
        case _ where line.contains(String(localized: .filobus)): return Color(red: 101/255, green: 179/255, blue: 46/255)
        case _ where line.contains("P") && !(line.contains("MXP")): return Color(red: 69/255, green: 56/255, blue: 0)
        
        ///OTHER LINES
        case "MXP": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP1": return Color(red: 140/255, green: 0, blue: 118/255)
        case "MXP2": return Color(red: 140/255, green: 0, blue: 118/255)
        case "SFM 6": return Color(red: 139/255, green: 35/255, blue: 29/255)
        case "REG": return Color(red: 226/255, green: 62/255, blue: 62/255)
        case "AV": return .red
        case "RV": return .red
        case String(localized: .aereoporto): return .cyan
        case _ where line.contains("R") && !line.contains("RE"): return Color.blue
        case _ where line.contains("RE") && !line.contains("REG"): return Color.red
        case let s where (1...33).contains(Int(s) ?? 0): return .orange
        case _ where line.starts(with: "N"): return Color(red: 2/255, green: 27/255, blue: 129/255)
        
        ///FALLBACK CASE
        default: return Color(red: 90/255, green: 180/255, blue: 85/255)
    }
}

func getCurrentTransportIcon(for lineLongName: String) -> String{
    switch(lineLongName){
        case "Suburbano":
            return "train.side.front.car"
        case "TILO":
            return "train.side.front.car"
        case "Malpensa Express":
            return "train.side.front.car"
            
        case "Metro":
            return "tram.tunnel.fill"
            
        case "Autoguidovie":
            return "bus.fill"
        case "STAV":
            return "bus.fill"
        case "Movibus":
            return "bus.fill"
            
        case String(localized: .tram):
            return "tram.fill"
        
        default:
            return "train.side.front.car"
    }
}

func getIconForFilter(for filterName: String) -> String{
    switch(filterName){
        case "Le tue linee":
            return "sparkle"
        case "Tutti":
            return "line.3.horizontal.decrease"
        case "Bus":
            return "bus.fill"
        case "Tram":
            return "tram.fill"
        case "Metropolitana":
            return "tram.tunnel.fill"
        case "Treno":
            return "train.side.front.car"
        case "In Corso":
            return "clock.badge.exclamationmark.fill"
        case "Programmati":
            return "calendar.badge.clock"
            
        default:
            return ""
    }
}

// MARK: DEEP LINK
extension Notification.Name {
    static let openLetueLinkInfo = Notification.Name("openLetueLinkInfo")
    static let openLineDetailFromWidget = Notification.Name("openLineDetailFromWidget")
    static let openTrainFilter = Notification.Name("openTrainFilter")
}

//EXTENSION: Save files also with arrays
extension Array: @retroactive RawRepresentable where Element == String {
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
        let transport = self.typeOfTransport.lowercased()
        
        let linesLower = self.lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        if favorites.contains("Bus") {
            let isRubberTire = transport.contains("bus") || transport.contains("autobus")
            let isMovibus = transport.contains("movibus") || linesLower.contains { $0.hasPrefix("z6") }
            let isStav = transport.contains("stav") || linesLower.contains { $0.hasPrefix("z5") }
            let isAutoguidovie = transport.contains("autoguidovie") || linesLower.contains {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }
            
            if isRubberTire && !isMovibus && !isStav && !isAutoguidovie {
                return true
            }
        }
        
        if favorites.contains("z6") {
            if transport.contains("movibus") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z6") }) { return true }
        }
        
        if favorites.contains("z55"){
            if transport.contains("stav") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z55") || $0.hasPrefix("z56") }) { return true }
        }
        
        if favorites.contains("z50"){
            if transport.contains("star") { return true }
            if linesLower.contains(where: { $0.hasPrefix("z50") || $0.hasPrefix("z51") }) { return true }
        }
        
        if favorites.contains("Autoguidovie") {
            if transport.contains("autoguidovie") { return true }
            if linesLower.contains(where: {
                $0.hasPrefix("z4") || $0.hasPrefix("z2")
            }) {
                return true
            }
        }
        
        if favorites.contains("Tram") {
            let isTram = transport.contains("tram") &&
                        !transport.contains("tram.fill.tunnel") &&
                        !transport.contains("metro")
            if isTram { return true }
        }
        
        for workLine in self.lines {
            let cleanWorkLine = workLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let upperLine = workLine.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            for fav in favorites {
                let cleanFav = fav.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if cleanWorkLine == cleanFav {
                    return true
                }
            }
            
            if favorites.contains("S") && upperLine.hasPrefix("S") && !isLineTILO(lineName: upperLine) {
                let suffix = upperLine.dropFirst()
                if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) {
                    return true
                }
            }
            
            if favorites.contains("R") && upperLine.hasPrefix("R") && !upperLine.hasPrefix("RE") {
                return true
            }
            
            if favorites.contains("RE") && upperLine.hasPrefix("RE") && !isLineTILO(lineName: upperLine) {
                return true
            }
            
            if(favorites.contains("Tilo") && isLineTILO(lineName: upperLine)) {
                return true
            }
        }
        
        return false
    }
    
    var isFinishedMoreThanOneDayAgo: Bool {
        let calendar = Calendar.current
        guard let dayDifference = calendar.dateComponents([.day], from: endDate, to: Date()).day else {
            return false
        }
        
        return dayDifference >= 1
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

extension URL: @retroactive Identifiable { public var id: String { absoluteString }}

extension Date: @retroactive RawRepresentable {
    private static let isoFormatter = ISO8601DateFormatter()

    public var rawValue: String {
        Date.isoFormatter.string(from: self)
    }

    public init?(rawValue: String) {
        if let date = Date.isoFormatter.date(from: rawValue) {
            self = date
        } else {
            self = Date()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.preferredControlTintColor = .systemBlue
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct HapticManager {
    static let shared = HapticManager()
    private let generator = UIImpactFeedbackGenerator(style: .light)
        
    func trigger() {
        generator.prepare()
        generator.impactOccurred()
    }
}

func isLineTILO(lineName: String) -> Bool {
    return (lineName == "S10" || lineName == "S20" || lineName == "S30" || lineName == "S40" || lineName == "S50" || lineName == "S90" || lineName == "RE80")
}

///URL Types
///In this section we create the code for open the URLs of Widgets
struct DeepLinkLine: Identifiable {
    let id = UUID()
    let name: String
}

struct DeepLinkLineDetailWrapper: View {
    let lineName: String
    @ObservedObject var viewModel: WorkViewModel
    @Environment(\.dismiss) private var dismiss

    private var lineInfo: LineInfo? {
        LinesView(viewModel: viewModel).fullLineInfo(for: lineName)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let info = lineInfo {
                LineDetailView(
                    lineName: info.name,
                    typeOfTransport: info.type,
                    branches: info.branches,
                    waitMinutes: info.waitMinutes,
                    workScheduled: getWorkScheduled(line: info.name, viewModel: viewModel),
                    workNow: getWorkNow(line: info.name, viewModel: viewModel),
                    viewModel: viewModel,
                    stations: info.stations,
                    accessibilityStatus: info.accessibilityStatus
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Linea non trovata")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
}

#Preview{
    @Previewable @State var showSetupScreen: Bool = false
    ContentView(showSetupScreen: $showSetupScreen)
}
