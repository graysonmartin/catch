import Foundation

extension Error {
    var isCancellation: Bool {
        self is CancellationError || (self as NSError).code == NSURLErrorCancelled
    }
}
