#if canImport(WidgetKit)
import WidgetKit
#endif
import Synchronization

/// Asks WidgetKit to draw the widgets and the complications again.
///
/// A widget reads the store on its own timeline, a quarter of an hour apart.
/// Without this call an expense the user has just added does not reach the
/// Home Screen or the watch face until that timer comes round.
///
/// WidgetKit is an outside system, so it is reachable through one seam: a
/// sealed launch swaps it for a recorder, and a UI test then never wakes a
/// widget extension it has no business running.
public enum WidgetRefresh {

    /// What a refresh does in a live app.
    public static let live: @Sendable () -> Void = {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static let handler = Mutex<@Sendable () -> Void>(live)
    private static let calls = Mutex<Int>(0)

    /// Call this after anything that changes what a widget shows: an expense,
    /// a limit, a rate, the home currency.
    public static func afterChange() {
        calls.withLock { $0 += 1 }
        handler.withLock { $0() }
    }

    /// Swaps what a refresh does. Only a launch may call this.
    public static func use(_ refresh: @escaping @Sendable () -> Void) {
        handler.withLock { $0 = refresh }
    }

    /// How many times the app has asked, for a test that wants to know.
    public static var callCount: Int { calls.withLock { $0 } }
}
