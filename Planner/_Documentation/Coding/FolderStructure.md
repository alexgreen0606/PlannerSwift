# Folder Structure

The app is organized into three layers, plus two support folders. Code is grouped by **domain**, not by kind: a domain's models, services, loaders, and views all live together in its module.

```
Planner/
├── App/              App entry, launch sequence, and screens
├── Modules/          Domain modules (one folder per domain)
├── Core/             Domain-agnostic building blocks
├── _Deprecated/      Legacy code awaiting removal
└── _Documentation/   Coding and UI conventions
```

## Dependency Rule

```
App  ──▶  Modules  ──▶  Core
```

- **App** may use anything.
- **Modules** may use Core and other modules.
- **Core** never references a module or a domain type (`Planner`, `PlannerEvent`, `Settings`, …).

If a Core file starts needing a domain type, it belongs in a module.

> Known exception: `Core/Persistence/ModelContext+LegacyEkEventMigration.swift` references `PlannerEvent` and `EKEventContext`. It is temporary and is removed along with `EKEventContext`.

## Where Does New Code Go?

1. **Used by one screen only?** Put it in that screen under `App/Screens/<Screen>/`.
2. **Belongs to a single domain, or used by 2+ screens?** Put it in `Modules/<Domain>/`. This includes services and loaders.
3. **Knows nothing about the domain?** Put it in `Core/`.
4. **Replaced but still referenced?** Put it in `_Deprecated/` with an `_old` suffix, and delete it once nothing uses it.

When screen code becomes shared (step 1 → step 2), move it into a module at that point.

---

## App

```
App/
├── 1_PlannerApp.swift          @main, model container, location services
├── 2_DataLoader.swift          Loads Settings
├── 3_EnvironmentLoader.swift   Creates services and injects them as environment objects
├── 4_Onboarding.swift          Onboarding gate, scene-phase and midnight hooks
├── 5_RootTabView.swift         Root tabs (Checklists, Trips, Planner)
├── Icons/                      Alternate app icons
└── Screens/
    ├── Checklist/
    ├── Folder/
    ├── Planner/                A single day's planner (opened as a full-screen cover)
    ├── PlannerTab/             The prominent Planner tab
    │   ├── List/               Upcoming planners / search results
    │   └── Calendar/           Paged month grid
    ├── Routine/
    ├── Settings/
    └── Trip/
```

The numbered files run in launch order.

Each screen has a `<Screen>Root.swift` and optional subfolders: `Components/`, `Forms/`, `Loaders/`, `Types/`, `Layout/`, `Extensions/`. Everything in a screen folder is used only by that screen.

When one screen switches between several views, as `PlannerTab` does between list and calendar, each view gets its own subfolder with the same optional subfolders inside.

---

## Modules

| Module | Responsibility |
|---|---|
| **Birthday** | Birthday calendar events matched to contacts (`ContactService`, `PlannerBirthdayItem`, `BirthdayLabel`). |
| **ChecklistItem** | Checklists, folders, and their items: model, predicates, changes, navigation, and forms. |
| **Event** | Protocols shared by `PlannerEvent` and `RoutineEventContext` (`EventDetails`, `EventListItem`) and the shared sort-date algorithm (`generateSortDate`). |
| **EventKit** | Access to the system calendar: `CalendarService`, `PlannerEkEventLoader`, `EkEventPlannerState` (Planner-only state for calendar events), and EventKit extensions. |
| **Location** | `Location` model, `LocationService` (device location), `LocationSearchService`, and the location form. |
| **Onboarding** | The onboarding flow: shared frame and buttons (`Views/`) and each step (`Screens/`). |
| **Planner** | `Planner` (one day), plus `PlannerService` (list, search, and routine/weather syncing), `PlannerCoverStore`, `TodayService`, `PlannerLoader`, and `PlannerHeader`. |
| **PlannerEvent** | `PlannerEvent` SwiftData model: predicates, changes, flagging/carry-over, and `RoutineEventRecordContext`. |
| **PlannerItem** | `PlannerItem`, the shared row model for PlannerEvents and calendar events. Includes the planner loaders (`PlannerContextLoader`, `PlannerItemContextLoader`, `EkEventPlannerStateLoader`), item changes, adornments, and the event form sheet. |
| **PlannerPreview** | The read-only day preview shared by the planner list and trip cards (`PlannerPreviewLoaderView`, `PlannerPreviewContext`, `PlannerPreviewContentView`). |
| **Routine** | Routines, routine events, and `syncRoutine` (applies a routine to a planner). |
| **Search** | `SearchService`, search queries and results, per-domain search scoring extensions, and the search UI (`PlannerSearchWrapperView` for the search bar, `PlannerSearchToolbarContent` for the filter, search, and reset buttons). |
| **Settings** | `Settings` model and app preferences (accent color, color scheme, homepage). |
| **Trip** | `Trip` model, `TripsContextLoader`, and trip UI helpers. |
| **Weather** | `PlannerWeather` model, WeatherKit syncing, `PlannerWeatherLoader`, and weather views. |

### Module Anatomy

Each module uses whichever of these subfolders it needs:

```
Modules/<Domain>/
├── Data/
│   ├── Models/        SwiftData @Model types
│   ├── Predicates/    static Predicate builders (lowercase file names, e.g. planners.swift)
│   ├── Modifiers/     ModelContext+<Domain>.swift (CRUD)
│   │   └── _Advanced/ Multi-step changes, with _Helpers/ for their internals
│   └── Constants/     Static seed or config data
├── Services/          ObservableObject services, injected via the environment
├── Loaders/           SwiftUI loader views, and the context types they produce
├── Types/             Plain structs and enums
├── Extensions/        <Type>+.swift extensions
├── Utilities/         Free functions
├── Views/             Reusable SwiftUI views (sub-features get their own folder)
├── UI/                Non-view UI configuration (deletion configs, labels)
├── Layout/            Layout constants
└── Navigation/        Navigation helpers
```

---

## Core

Building blocks with no knowledge of the domain.

```
Core/
├── Configurations/          IconConfig, ToggleConfig
├── Layout/                  Shared layout constants
├── Persistence/             ModelContext helpers (save, cleanup, migrations)
├── Primitives+/             Extensions on Swift/SwiftUI types (String+, View+, …)
├── Types/                   Shared enums (Month, TabId)
├── UI/                      Shared UI constants and messages
├── Views/                   Base views (_Buttons, _Forms, _Text, icons, toolbars)
├── _Confirmation/           Confirmation-dialog modifier
├── _Datestamps/             Datestamp ("yyyy-MM-dd") parsing, formatting, and math
├── _ListItemDetails/        Protocol for persisted list rows (used by the legacy list)
├── _SortableTextfieldList/  Generic sortable, editable text-field list (ListEngine)
└── _Toasts/                 Toast presentation
```

Underscore-prefixed folders are self-contained features. Unprefixed folders are grab-bags of small shared pieces.

---

## _Deprecated

Legacy code still referenced by live screens. Nothing new should depend on it.

| Item | Blocked on |
|---|---|
| `_SortableTextfieldList_old/`, `*_old.swift` list components | Moving the Checklist, Folder, and Routine screens to `Core/_SortableTextfieldList`. |
| `EkEventContext/` | Every device having run `migrateLegacyEkEventPlannerEvents`. Remove it together with the `eKEventContext` branches in PlannerEvent predicates and the calendar-record deletion chain. |

---

## Naming

- Folders are `PascalCase`. Use plural names for collections (`Services`, `Loaders`, `Views`).
- An underscore prefix (`_Advanced`, `_Forms`, `_Datestamps`) marks a sub-feature or self-contained group.
- Extension files are named `<Type>+.swift`, or `<Type>+<Topic>.swift` for focused extensions.
- See `NamingConventions.md` for type and symbol naming.
