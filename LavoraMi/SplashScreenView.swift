//
//  SplashScreenView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 1.0
    @State private var scaleEffect = 1.0
    @State private var contentOpacity: Double = 0
    @State private var contentLoaded = false
    @State private var showSetupScreen: Bool = false
    @State private var showMaintenance: Bool = false
    @State private var obsoleteVersion: Bool = false
    @State private var showNoConnection: Bool = false
    @State private var status: Double = 0
    @AppStorage("hasNotCompletedSetup") private var hasNotCompletedSetup = true
    @StateObject private var viewModel = WorkViewModel()
    @State private var pendingDeepLink: URL? = nil

    var body: some View {
        ZStack {
            if contentLoaded {
                if(showMaintenance){
                    MaintenanceView(maintenanceDeps: viewModel.maintenanceDeps, maintenanceDepsEn: viewModel.maintenanceDepsEn, maintenanceDepsEs: viewModel.maintenanceDepsEs) {
                        showMaintenance = false
                    }
                    .opacity(contentOpacity)
                }
                else if (!obsoleteVersion){
                    ContentView(showSetupScreen: $showSetupScreen)
                        .opacity(contentOpacity)
                }
                
                else if(obsoleteVersion) {
                    ObsoleteVersionView()
                        .opacity(contentOpacity)
                }
            }
            VStack(spacing: 12) {
                Image("icon")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .scaleEffect(scaleEffect)
                
                if(showNoConnection){
                    ProgressView(value: status, total: 1.0)
                        .tint(.red)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                    
                    Label("Bloccato qui? Controlla la tua connessione.", systemImage: "wifi.exclamationmark")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
            }
            .opacity(opacity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if !contentLoaded {
                    withAnimation {
                        status = 0.5
                        showNoConnection = true
                    }
                }
            }
            viewModel.fetchRequirements {
                showMaintenance = viewModel.maintenanceModeEnabled
                status = 1
                contentLoaded = true
                showNoConnection = false
                
                let current = Bundle.main.shortVersion
                let minimum = viewModel.minimumVersion
                
                let comparisonResult = current.compare(minimum, options: .numeric)
                
                if comparisonResult == .orderedAscending {
                    obsoleteVersion = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startAnimation()
                }
            }
        }
        .onOpenURL { url in
            if contentLoaded {
                handleDeepLink(url)
            } else {
                pendingDeepLink = url
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            scaleEffect = 0.5
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            scaleEffect = 1000
        }
        withAnimation(.easeIn(duration: 0.2).delay(0.95)) {
            contentOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.15).delay(1.05)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if hasNotCompletedSetup && pendingDeepLink == nil {
                showSetupScreen = true
            }
            if let url = pendingDeepLink {
                handleDeepLink(url)
                pendingDeepLink = nil
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "lavorami" else { return }

        if url.host == "letueline" {
            NotificationCenter.default.post(name: .openLetueLinkInfo, object: nil)
        }

        if url.host == "linea" {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let nome = components.queryItems?.first(where: { $0.name == "nome" })?.value
            else { return }
            NotificationCenter.default.post(name: .openLineDetailFromWidget, object: nome)
        }
        
        if url.host == "train" {
            NotificationCenter.default.post(name: .openTrainFilter, object: nil)
        }
    }
}

#Preview {
    SplashScreenView()
}
