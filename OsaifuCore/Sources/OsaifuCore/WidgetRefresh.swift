#if canImport(WidgetKit)
import WidgetKit
#endif

/// Asks WidgetKit to draw the widgets and the complications again.
///
/// A widget reads the store on its own timeline, a quarter of an hour apart.
/// Without this call an expense the user has just added does not reach the
/// Home Screen or the watch face until that timer comes round.
public enum WidgetRefresh {

    /// Call this after anything that changes what a widget shows: an expense,
    /// a limit, a rate, the home currency.
    public static func afterChange() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
