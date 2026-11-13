import SwiftData
import SwiftUI
import OsaifuSync

/// Asks WidgetKit to draw again when iCloud delivers a change from another
/// device.
///
/// Every local write calls `WidgetRefresh.afterChange()` itself. A change that
/// arrives from another device belonged to nobody: an expense added on the
/// phone left the iPad's widget, and the watch face, showing the figure from
/// before it until the timeline came round a quarter of an hour later.
///
/// It can only fail closed. `HistoryObserver` throws where the store keeps no
/// history, and then this does nothing at all, which is where the app stood
/// before it.
private struct RemoteChangeRefresh: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    /// Made once the view is up, because it needs the container the app
    /// opened, and it reports a change by counting one.
    @State private var changes: HistoryObserver?

    func body(content: Content) -> some View {
        content
            .task {
                guard changes == nil else { return }
                // No models named: every one of them changes what a widget
                // shows, so every one of them is worth a redraw.
                changes = try? HistoryObserver(modelContainer: modelContext.container)
            }
            .onChange(of: changes?.eventCounter) { _, count in
                // The observer starts at zero, so only a count it has moved
                // is a change that has arrived.
                guard let count, count > 0 else { return }
                WidgetRefresh.afterChange()
            }
    }
}

public extension View {
    /// Keeps the widgets and the complications in step with what iCloud
    /// delivers, for as long as this app is running.
    func refreshesWidgetsOnRemoteChange() -> some View {
        modifier(RemoteChangeRefresh())
    }
}
