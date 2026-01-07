//
//  NotificationManager
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permesso notifiche concesso")
            } else if let error = error {
                print("Errore permessi: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleWorkAlerts(for work: WorkItem) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: work.endDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let contentDayOf = UNMutableNotificationContent()
        contentDayOf.title = "Lavori terminati!"
        contentDayOf.body = "I lavori per \(work.title) in \(work.roads) dovrebbero terminare oggi, consulta il sito di \(work.company)"
        contentDayOf.sound = .default
        
        if let dateOf = calendar.date(from: dateComponents), dateOf > Date() {
            let triggerDayOf = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let requestDayOf = UNNotificationRequest(identifier: "\(work.id.uuidString)_END", content: contentDayOf, trigger: triggerDayOf)
            center.add(requestDayOf)
            print("Notifica programmata per la fine: \(dateOf.formatted())")
        }
        
        if let dayBeforeDate = calendar.date(byAdding: .day, value: -1, to: work.endDate) {
            
            var dayBeforeComponents = calendar.dateComponents([.year, .month, .day], from: dayBeforeDate)
            dayBeforeComponents.hour = 9
            dayBeforeComponents.minute = 0
            
            if dayBeforeDate > Date() {
                let contentDayBefore = UNMutableNotificationContent()
                contentDayBefore.title = "⚠️ I lavori finiscono domani!"
                contentDayBefore.body = "Domani terminano i lavori in \(work.roads) della linea \(work.lines.joined(separator: ", ")), consulta il sito di \(work.company)"
                contentDayBefore.sound = .default
                
                let triggerDayBefore = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
                let requestDayBefore = UNNotificationRequest(identifier: "\(work.id.uuidString)_PRE", content: contentDayBefore, trigger: triggerDayBefore)
                center.add(requestDayBefore)
                print("Notifica programmata per il preavviso: \(dayBeforeDate.formatted())")
            }
        }
    }
    
    func sendNotification(){
        let lines = ["90", "91"]
        let contentDayBefore = UNMutableNotificationContent()
        contentDayBefore.title = "⚠️ I lavori finiscono domani!"
        contentDayBefore.body = "Domani terminano i lavori in Piazzale Lodi della linea \(lines.joined(separator: ", ")), consulta il sito di ATM"
        contentDayBefore.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: contentDayBefore, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore invio notifica: \(error.localizedDescription)")
            } else {
                print("Notifica schedulata con successo")
            }
        }
    }
    
    func removeWorkAlerts(for work: WorkItem) {
        let center = UNUserNotificationCenter.current()
        let identifiers = ["\(work.id.uuidString)_END", "\(work.id.uuidString)_PRE"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Notifiche rimosse per: \(work.title)")
    }
    
    func syncNotifications(for works: [WorkItem], favorites: [String]) {
            let center = UNUserNotificationCenter.current()
            for work in works {
                if work.matchesFavorites(favorites) {
                    scheduleWorkAlerts(for: work)
                    print("Attivata notifica per: \(work.title) (Match preferiti)")
                } else {
                    removeWorkAlerts(for: work)
                }
            }
        }
}
