import Foundation

public enum APNsPayloadDecoder {

    // MARK: - Public

    /// Decodes an APNs push notification `userInfo` dictionary into a
    /// `NotificationPayload`.
    ///
    /// Looks for the custom payload under the `"data"` key first.  If that key
    /// is missing, attempts to decode from the top-level dictionary (excluding
    /// the `"aps"` key).
    ///
    /// Returns `nil` for malformed or unrecognised payloads instead of throwing.
    public static func decode(from userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        let jsonObject: Any

        if let data = userInfo["data"] {
            jsonObject = data
        } else {
            // Fall back: strip the aps key and try the rest
            var stripped = userInfo
            stripped.removeValue(forKey: "aps")
            // Convert AnyHashable keys to String keys for serialization
            var stringKeyed: [String: Any] = [:]
            for (key, value) in stripped {
                guard let stringKey = key as? String else { continue }
                stringKeyed[stringKey] = value
            }
            guard !stringKeyed.isEmpty else { return nil }
            jsonObject = stringKeyed
        }

        guard let dict = jsonObject as? [String: Any],
              let serialized = try? JSONSerialization.data(
                  withJSONObject: dict
              ) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NotificationPayload.self, from: serialized)
    }
}
