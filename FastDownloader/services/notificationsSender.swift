//
//  notificationsSender.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 05-09-26.
//

import Foundation
import UserNotifications
import OSLog


final class NotificationSender {
    static let shared = NotificationSender()
    private let logger = Logger.notificationSender
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() {
        center.requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error {
                self.logger.error("Notification permission error: \(error)")
                return
            }

            self.logger.info("Notification permission granted: \(granted)")
        }
    }

    func send(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error {
                self.logger.error("Failed to send notification: \(error)")
            }
        }
    }
}
