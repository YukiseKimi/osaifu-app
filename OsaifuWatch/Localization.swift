import Foundation

extension String {
    /// This English text, as the watch app's catalog has it in the reader's
    /// language.
    ///
    /// A category names itself in a plain Swift string, because the model
    /// layer carries no UI framework and holds no resources of its own.
    /// `Text(aString)` translates nothing, so a name on its way to the
    /// screen comes through here. The phone has the same bridge against its
    /// own catalog: a lookup is always in the bundle of the app doing it.
    var localizedInApp: String {
        String(localized: String.LocalizationValue(self))
    }
}
