//
//  WorkViewModel.swift
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import Foundation
import Combine
import SwiftUI

class WorkViewModel: ObservableObject {
    @Published var items: [WorkItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var strikeEnabled: Bool = false
    @Published var companiesStrikes: String = ""
    @Published var dateStrike: String = ""
    
    private let urlString = "https://cdn-playepik.netlify.app/LavoraMI/lavoriAttuali.json"
    private let urlVariables = "https://cdn-playepik.netlify.app/LavoraMI/_vars.json"
    
    func fetchWorks() {
        guard let url = URL(string: urlString) else {
            self.errorMessage = "URL non valido"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Errore connessione: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Nessun dato ricevuto"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let decodedItems = try decoder.decode([WorkItem].self, from: data)
                    self?.items = decodedItems
                    
                    if let savedFavoritesData = UserDefaults.standard.data(forKey: "linesFavorites"),
                       let savedFavorites = try? JSONDecoder().decode([String].self, from: savedFavoritesData) {
                        
                        NotificationManager.shared.syncNotifications(for: decodedItems, favorites: savedFavorites)
                    }
                } catch {
                    self?.errorMessage = "Errore lettura dati: \(error.localizedDescription)"
                    print("Errore di decoding: \(error)")
                }
            }
        }.resume()
    }
    
    func fetchVariables() {
        guard let url = URL(string: urlVariables) else {
            self.errorMessage = "URL non valido"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Si è verificato un errore: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Nessun dato trovato."
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(RemoteConfigData.self, from: data)
                DispatchQueue.main.async {
                    self?.strikeEnabled = (result.enableStrike == "true")
                    self?.companiesStrikes = result.companies
                    self?.dateStrike = result.date
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Errore lettura dati: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct RemoteConfigData: Codable {
    let enableStrike: String
    let date: String
    let companies: String
}
