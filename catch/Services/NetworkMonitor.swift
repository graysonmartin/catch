import Foundation
import Network
import Observation

@Observable
@MainActor
final class NetworkMonitor: @unchecked Sendable {
    private(set) var isConnected = true

    @ObservationIgnored
    private let monitor = NWPathMonitor()

    @ObservationIgnored
    private let queue = DispatchQueue(label: "com.catch.networkMonitor", qos: .utility)

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
