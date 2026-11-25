import Foundation

extension String {
    /// This English text, as the app's catalog has it in the reader's
    /// language.
    ///
    /// The model layer names a category, a period and a theme in plain Swift
    /// strings, because it carries no UI framework and holds no resources of
    /// its own. `Text(aString)` does not translate anything — only a literal
    /// written in a view does — so a name on its way to the screen comes
    /// through here, where the English text is the key the catalog is
    /// written against.
    ///
    /// It is in the app target on purpose: the lookup is in the app's own
    /// bundle, which is where `Localizable.xcstrings` lives.
    var localizedInApp: String {
        String(localized: String.LocalizationValue(self))
    }
}
