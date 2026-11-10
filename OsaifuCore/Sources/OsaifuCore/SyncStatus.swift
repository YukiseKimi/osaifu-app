import CloudKit
import Foundation
import SwiftData

/// What iCloud says about the account that would carry the expenses.
public enum CloudAccount: Equatable, Sendable {
    /// Not read yet, or iCloud could not answer. The app shows "Connecting".
    case unknown
    /// Signed in. The expenses reach the other devices.
    case available
    /// Signed out, or iCloud Drive is off.
    case noAccount
    /// A profile or a parental control stops iCloud.
    case restricted

    public var syncs: Bool { self == .available }
}

/// Reads what the app can honestly say about sync.
///
/// SwiftData reports no count of changes that wait to upload and no event for
/// an upload that finished, so the app says two true things instead: whether
/// the account can sync, and when the data last changed.
public enum SyncStatus {

    /// The account state of the app's CloudKit container.
    ///
    /// iCloud does not always answer. On a machine with no account and no
    /// reachable container the call can hang, which once left the badge saying
    /// "connecting" for as long as the app was open, so the read gives up.
    public static func account(
        containerID: String = StoreSetup.cloudContainerID,
        timeout: Duration = .seconds(5)
    ) async -> CloudAccount {
        // CKContainer(identifier:) traps, it does not throw, in a process
        // that the container is not in the entitlements of. An unsigned build
        // is such a process, and a catch cannot save it. The token is nil in
        // exactly those processes, and in every signed-out one, where the
        // honest answer is the same: no account.
        guard FileManager.default.ubiquityIdentityToken != nil else { return .noAccount }

        return await withTaskGroup(of: CloudAccount?.self) { group in
            group.addTask {
                do {
                    return state(for: try await CKContainer(identifier: containerID).accountStatus())
                } catch {
                    return .unknown
                }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? .unknown
        }
    }

    /// What one of CloudKit's statuses means for the app.
    static func state(for status: CKAccountStatus) -> CloudAccount {
        switch status {
        case .available: .available
        case .noAccount: .noAccount
        case .restricted: .restricted
        case .couldNotDetermine, .temporarilyUnavailable: .unknown
        @unknown default: .unknown
        }
    }

    /// When an expense last changed, on this device or another one.
    public static func lastChange(in context: ModelContext) throws -> Date? {
        var descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.updatedAt
    }
}
