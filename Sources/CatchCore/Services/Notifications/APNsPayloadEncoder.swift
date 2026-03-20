import Foundation

public enum APNsPayloadEncoder {

    // MARK: - Public

    /// Encodes a `NotificationPayload` into an APNs-compatible JSON dictionary.
    ///
    /// The result includes the standard `aps` wrapper with `alert`, `sound`, and
    /// `thread-id`, plus the custom payload data under the `"data"` key.
    public static func encode(
        _ payload: NotificationPayload,
        title: String,
        body: String,
        sound: String = "default"
    ) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payloadData = try encoder.encode(payload)

        guard let payloadDict = try JSONSerialization.jsonObject(
            with: payloadData
        ) as? [String: Any] else {
            throw APNsPayloadEncodingError.serializationFailed
        }

        let aps: [String: Any] = [
            "alert": [
                "title": title,
                "body": body
            ],
            "sound": sound,
            "thread-id": payload.collapseKey ?? payload.notificationType.rawValue
        ]

        return [
            "aps": aps,
            "data": payloadDict
        ]
    }
}

public enum APNsPayloadEncodingError: Error, Sendable, Equatable {
    case serializationFailed
}
