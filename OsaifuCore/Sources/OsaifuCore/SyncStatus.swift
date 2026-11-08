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
    public static func account(containerID: String = StoreSetup.cloudContainerID) async -> CloudAccount {
        do {
            switch try await CKContainer(identifier: containerID).accountStatus() {
            case .available: return .available
            case .noAccount: return .noAccount
            case .restricted: return .restricted
            case .couldNotDetermine, .temporarilyUnavailable: return .unknown
            @unknown default: return .unknown
            }
        } catch {
            return .unknown
        }
    }

    /// When an expense last changed, on this device or another one.
    public static func lastChange(in context: ModelContext) throws -> Date? {
        var descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.updatedAt
    }
}
