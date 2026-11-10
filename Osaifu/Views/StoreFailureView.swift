import SwiftUI
import OsaifuModel

/// Shown in place of the app when the store cannot open, which almost always
/// means a migration did not finish. The expenses are still on the device, and
/// the view names the copy that `StoreSetup` made first.
struct StoreFailureView: View {
    let error: any Error

    private var backupPath: String? {
        (error as? StoreSetup.Failure)?.backupURL?.path(percentEncoded: false)
    }

    private var reason: String {
        ((error as? StoreSetup.Failure)?.underlying ?? error).localizedDescription
    }

    var body: some View {
        ContentUnavailableView {
            Label("Osaifu Cannot Open Your Data", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: 12) {
                Text("The update to your expenses did not finish. Nothing was deleted.")
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let backupPath {
                    VStack(spacing: 4) {
                        Text("A copy of your data is safe at:")
                            .font(.footnote)
                        Text(backupPath)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    StoreFailureView(error: StoreSetup.Failure(
        underlying: NSError(
            domain: "NSCocoaErrorDomain",
            code: 134110,
            userInfo: [NSLocalizedDescriptionKey: "The store is not compatible with this version of the app."]
        ),
        backupURL: URL(filePath: "/tmp/Backups/default-20261108T120000Z.store")
    ))
}
