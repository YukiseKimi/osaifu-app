import Combine
import CoreData
import SwiftUI
import OsaifuSync

/// Asks WidgetKit to draw again when iCloud delivers a change from another
/// device.
///
/// Every local write calls `WidgetRefresh.afterChange()` itself. A change
/// that arrives from another device belonged to nobody: an expense added on
/// the phone left the iPad's widget, and the watch face, showing the figure
/// from before it until the timeline came round a quarter of an hour later.
///
/// SwiftData mirrors iCloud through Core Data, and the store posts this
/// notification when the CloudKit import, or another process, writes to it.
/// SwiftData's own `HistoryObserver` listens for the same thing and then
/// reads the transactions, which this has no use for: all it needs to know
/// is that something arrived. It also needs the iOS 27 SDK, and the runner
/// that builds this project has Xcode 26, while this notification has been
/// there since iOS 12.
///
/// It fails closed. A store that posts nothing leaves the widgets where they
/// stood before this: a quarter of an hour behind.
private struct RemoteChangeRefresh: ViewModifier {

    /// A first sync writes every expense the account holds, and posts as it
    /// goes. The wait gathers that burst into the one redraw it deserves.
    ///
    /// No closure of ours may sit before the debounce. Core Data posts this
    /// notification on its own background queue, and a closure written in a
    /// view is main-actor code, so Swift 6 traps the moment it runs there
    /// (`_dispatch_assert_queue_fail`). The debounce delivers on the main run
    /// loop, so everything after it is on the main thread.
    private var remoteChanges: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content.onReceive(remoteChanges) { _ in
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
