import ActivityKit
import Foundation

/// Live Activity payload. Shown on the Lock Screen, in the Dynamic Island and, on iPhone Duo,
/// on the outer display while the phone is folded. This is the "fold to focus" surface.
struct ShelfActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the session ends. The system renders the countdown from this, so no updates are needed.
        var endDate: Date
        /// Number of apps currently shielded, for the subtitle.
        var shieldedCount: Int
        /// Current streak, so the lock screen reminds them what an early exit costs.
        var streak: Int
    }

    /// When the session started.
    var startDate: Date
    var plannedMinutes: Int
}
