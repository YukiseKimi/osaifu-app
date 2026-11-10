// OsaifuModel
//
// The expense records, the categories, the currencies and the analytics that
// every Osaifu app shares: the iPhone app, the iPad dashboard, the Mac app and
// the watch app.
//
// It imports Foundation and SwiftData and nothing else. No SwiftUI, so no
// screen can be written here by accident; no CloudKit and no WidgetKit, so
// the rules about money stay testable without them. Those live in OsaifuSync
// and OsaifuUI, which depend on this and never the other way round.
