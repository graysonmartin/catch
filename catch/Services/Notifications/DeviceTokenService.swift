import Foundation
import os
import UIKit
import UserNotifications
import CatchCore
import Supabase

@MainActor
final class DeviceTokenService: DeviceTokenServiceProtocol, @unchecked Sendable {

    // MARK: - Dependencies

    private let clientProvider: any SupabaseClientProviding
    private let getCurrentUserID: @Sendable () -> String?
    private let notificationCenter: UNUserNotificationCenter

    private static let tableName = "device_tokens"
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "DeviceTokenService")

    // MARK: - Init

    init(
        clientProvider: any SupabaseClientProviding,
        getCurrentUserID: @escaping @Sendable () -> String?,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.clientProvider = clientProvider
        self.getCurrentUserID = getCurrentUserID
        self.notificationCenter = notificationCenter
    }

    // MARK: - DeviceTokenServiceProtocol

    func registerForPushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func syncToken(_ token: Data) async {
        guard let userID = getCurrentUserID() else { return }

        let hexToken = hexEncodedString(from: token)
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif

        let payload = DeviceTokenPayload(
            userID: userID,
            token: hexToken,
            environment: environment
        )

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .upsert(payload, onConflict: "token")
                .execute()
        } catch {
            logger.error("Failed to sync token: \(error.localizedDescription, privacy: .public)")
        }
    }

    func clearToken() async {
        guard let userID = getCurrentUserID() else { return }

        do {
            try await clientProvider.client
                .from(Self.tableName)
                .delete()
                .eq("user_id", value: userID)
                .execute()
        } catch {
            logger.error("Failed to clear tokens: \(error.localizedDescription, privacy: .public)")
        }
    }

    func requestPermissionIfNeeded() async {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await notificationCenter.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                if granted {
                    registerForPushNotifications()
                }
            } catch {
                logger.error("Permission request failed: \(error.localizedDescription, privacy: .public)")
            }
        case .authorized, .provisional, .ephemeral:
            registerForPushNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Payload

private struct DeviceTokenPayload: Encodable {
    let userID: String
    let token: String
    let environment: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case token
        case environment
    }
}
