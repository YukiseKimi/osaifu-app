<p align="center">
  <img src=".github/banner.svg" alt="Osaifu — multiplatform expense tracker" width="100%">
</p>

<p align="center">
  <a href="https://github.com/YukiseKimi/osaifu-app/actions/workflows/tests.yml"><img alt="Tests" src="https://github.com/YukiseKimi/osaifu-app/actions/workflows/tests.yml/badge.svg"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-iOS%20%7C%20macOS-1B3A5B">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-SwiftUI%20%2B%20SwiftData-orange">
  <img alt="Sync" src="https://img.shields.io/badge/sync-iCloud%20CloudKit-3478F6">
</p>

# Osaifu （お財布）

**Osaifu** is a multiplatform personal expense tracker for **iOS and macOS**. Log what you
spend, tag it with a common category, and see where your money goes — by month and over time.
Your data syncs across your devices through **iCloud**.

> *Osaifu* (お財布) is Japanese for "wallet."

## Features

- **Quick entry** — add an expense with an amount, a category, a date, and an optional note.
- **This Month overview** — a donut chart of spending by category with the running monthly total and a per-category breakdown.
- **Expenses list** — every expense in a chronological list, grouped into month sections. Tap to edit, swipe to delete.
- **History** — a month-by-month stacked bar chart so you can compare spending across months and categories.
- **Editing & deleting** — correct any past entry; changes are saved and synced automatically.
- **Currency** — choose your display currency in Settings; every amount re-formats instantly.
- **Sample data** — populate randomized expenses (or wipe everything) from Settings for quick exploration.
- **iCloud sync** — built on SwiftData + CloudKit, so your expenses follow you across devices.

## Categories

Food &amp; Dining · Groceries · Transport · Housing · Utilities · Health · Entertainment ·
Shopping · Education · Travel · Other — each with its own icon and a consistent color across all charts.

## Tech stack

| Area | Technology |
| --- | --- |
| UI | SwiftUI (multiplatform, single shared codebase) |
| Charts | Swift Charts (`SectorMark` donut, stacked `BarMark`) |
| Persistence | SwiftData (`@Model`, `@Query`) |
| Sync | CloudKit via SwiftData's automatic iCloud mirroring |
| Settings | `@AppStorage` |

## Requirements

- Xcode with the **iOS 27 / macOS 27** SDKs
- An Apple Developer account (required for the iCloud/CloudKit capability)

## Getting started

1. Open the project in Xcode and select the **MyApp** scheme.
2. In **Signing &amp; Capabilities**, choose your **Team**.
3. Confirm the **iCloud** capability has **CloudKit** enabled and the container
   `iCloud.com.satsurakyno.MyApp` is selected (recreate it under your own team/bundle ID if needed).
4. Build and run on an iOS simulator/device or on your Mac.
5. Open **Settings → Add Sample Data** to see the charts populated immediately.

To test sync, run the app on two devices/simulators signed into the **same iCloud account** and add an expense on one.

## Project structure

```
MyApp/
├─ ContentView.swift          # App entry point + RootView (the TabView)
├─ Models/
│  ├─ Expense.swift           # SwiftData @Model (CloudKit-compatible)
│  ├─ ExpenseCategory.swift   # Categories with titles, SF Symbols, and colors
│  └─ Currency.swift          # Selectable currencies for display
├─ Logic/
│  ├─ ExpenseAnalytics.swift  # Aggregation helpers + currency formatting
│  └─ SampleData.swift        # Randomized example data generator
└─ Views/
   ├─ OverviewView.swift      # This-month donut chart + breakdown
   ├─ ExpensesListView.swift  # Chronological list grouped by month (edit/delete)
   ├─ HistoryView.swift       # Month-by-month stacked bar chart
   ├─ ExpenseFormView.swift   # Add/edit form
   └─ SettingsView.swift      # Currency picker + sample-data tools
```

## Roadmap

- **watchOS** companion app (the model and analytics are already shareable)
- Monthly **budget limits** per category with progress and over-budget warnings
- CSV export

## License

Not yet licensed — all rights reserved for now. A license may be added later.
