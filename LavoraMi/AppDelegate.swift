//
//  AppDelegate.swift
//  LavoraMi
//
//  Created by Andrea Filice on 06/01/26.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import FirebasePerformance

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(handlePushToggle(_:)), name: NSNotification.Name("pushNotificationsToggled"), object: nil)

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return true
    }

    @objc func handlePushToggle(_ notification: Notification) {
        guard let enabled = notification.object as? Bool else { return }
        if enabled {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            Messaging.messaging().deleteToken { _ in
                UserDefaults.standard.removeObject(forKey: "fcmToken")
            }
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            guard let token = token else { return }
            UserDefaults.standard.set(token, forKey: "fcmToken")
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Errore APNs: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        UserDefaults.standard.set(token, forKey: "fcmToken")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let pushAbilitate = UserDefaults.standard.object(forKey: "enablePushNotifications") == nil ? true : UserDefaults.standard.bool(forKey: "enablePushNotifications")
        completionHandler(pushAbilitate ? [.banner, .sound, .badge, .list] : [])
    }
}
