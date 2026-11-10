import OsaifuCore
import SwiftUI

/// The four categories this user picks most, as symbols. One tap picks one.
///
/// The watch has no room for names in the row, so the name of the chosen
/// category sits above it.
struct CategoryRow: View {
    let categories: [ExpenseCategory]
    @Binding var chosen: ExpenseCategory?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(categories) { category in
                Button {
                    chosen = category
                } label: {
                    Image(systemName: category.systemImage)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, minHeight: 18)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(chosen == category ? category.color : .secondary)
                .accessibilityLabel(category.title)
                .accessibilityAddTraits(chosen == category ? [.isSelected] : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var chosen: ExpenseCategory?
    return CategoryRow(
        categories: Array(ExpenseCategory.allCases.prefix(4)),
        chosen: $chosen
    )
}
