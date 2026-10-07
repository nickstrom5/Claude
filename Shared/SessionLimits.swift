import Foundation

/// Duration rules, in a file every target compiles. The intent runs inside the widget
/// extension, which cannot see `ScreenTimeManager`, so the floor cannot live there.
///
/// The floor is DeviceActivity's minimum monitored window: a shorter session has no schedule
/// the monitor extension can use, so it would rely on the app being alive at the end. A killed
/// app would then leave the shield up.
enum SessionLimits {
    static let minimumMonitoredMinutes = 15
    static let maximumMinutes = 240
}
