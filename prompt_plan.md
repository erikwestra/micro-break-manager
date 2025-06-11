# Micro-Break Manager – Development Blueprint

## 1. High-Level Blueprint ("What are we building?")

| # | Area | Key Decisions |
|---|------|---------------|
| 1 | **Platform** | Flutter 3.x, targeting macOS (.app bundle) |
| 2 | **Architecture** | MVVM-ish with Riverpod for state, `path_provider` + Dart `io` for files |
| 3 | **Models** | `MicroBreakItem`, `MicroBreakList`, `LogEntry` |
| 4 | **Storage** | Per-list `.txt` files in `~/Library/Application Support/MicroBreak/lists/` and daily log files in `…/logs/` |
| 5 | **Business Logic** | `RoundRobinManager` maintains list & item indices; save after successful break |
| 6 | **UI** | • Resizable **MainWindow**  <br>• Modal **SetupListsDialog**  <br>• Modal **ViewLogsDialog** |
| 7 | **Interaction** | `Space` = start/finish, `Esc` = cancel; menu bar: About / Quit / Setup / View Logs |
| 8 | **Persistence** | Delete logs > 30 days on launch/exit |
| 9 | **Error Handling** | Graceful skips + banner warnings; never crash on malformed file |
|10 | **Testing** | Pure-Dart tests for parsing, cycling, log rotation; widget tests for keyboard & modals |

---

## 2. Medium-Sized Iterative Chunks ("How will we get there safely?")

| Chunk | Goal |
|-------|------|
| **C1** ✅ | Scaffold Flutter macOS project, add core deps, CI workflow |
| **C2** ✅ | Implement data models + tab-delimited parsing & serialization |
| **C3** ✅ | `FileStorageService` (read/write lists & logs, 30-day purge) |
| **C4** ✅ | `RoundRobinManager` with unit tests (list & item progression) |
| **C5** | AppState (Riverpod providers) wiring models ↔ storage ↔ round-robin |
| **C6** | Minimal MainWindow: idle screen, keyboard shortcuts, state hookup |
| **C7** | `LoggingService`: create daily log file, append entries, unit tests |
| **C8** | `SetupListsDialog` (sidebar CRUD, editable textarea, save/cancel) |
| **C9** | `ViewLogsDialog` (sidebar dates, read-only viewer) |
| **C10** | macOS menu bar integration + routing to dialogs |
| **C11** | Refinement pass: error banners, edge-case tests, CI badge |
| **C12** | Packaging: icons, entitlements, notarization script |

Each chunk is small enough to finish in a day, yet large enough to yield visible progress.

---

## 3. Right-Sized Micro-Steps ("Exact order of work")

### C1 – Project Scaffold
1. Install Flutter macOS deps & verify `flutter doctor`.
2. `flutter create micro_break_manager` (desktop template).
3. Add `riverpod`, `path_provider`, `mocktail`, `flutter_test` to **pubspec.yaml**.
4. Configure GitHub Actions CI to run `flutter test`.
5. Run a “Hello macOS” window smoke test.

### C2 – Models & Parsing
1. Create `models/` with `micro_break_item.dart`, `micro_break_list.dart`, `log_entry.dart`.
2. Implement `.fromTsv()` and `.toTsv()` for each model.
3. Unit-test round-trip parse/serialize.
4. Add null-safety lint rules.

### C3 – FileStorageService
1. Create service skeleton with `getAppDir()` via `path_provider`.
2. Implement `readLists()` returning `List<MicroBreakList>`.
3. Implement `saveList(MicroBreakList)` (overwrite).
4. Implement `readDailyLog(date)`, `appendLogEntry()`.
5. Implement `purgeOldLogs(keepDays: 30)`; unit-test with `Directory` mocks.

### C4 – RoundRobinManager
1. Store `listIndex` & per-list `itemIndex`.
2. `nextItem()` returns tuple *(list, item)*.
3. `cancelSelection()` rolls back index changes.
4. Unit-test cycling with 2 lists, uneven lengths.

### C5 – AppState Providers
1. Create `storageProvider`, `roundRobinProvider`.
2. Write integration test: providers load lists & deliver first item.

### C6 – MainWindow MVP
1. Basic `Scaffold` with centered text.
2. Wire `Space` → `startBreak()`, second `Space` → `finishBreak()`.
3. Wire `Esc` → `cancelBreak()`.
4. Show current item text or idle hint.
5. Widget test: key events update UI state.

### C7 – LoggingService
1. On `finishBreak`, call `appendLogEntry()`.
2. Unit-test correct timestamps & file content.
3. Purge logic invoked on launch & exit.

### C8 – SetupListsDialog
1. Sidebar `ListView` sorted alphabetically.
2. Buttons: ➕ Add, ✏️ Rename, 🗑️ Delete (immediate).
3. Editable `TextField` for items with Save / Cancel.
4. Provider updates & list file write on Save.
5. Widget test: CRUD round-trip.

### C9 – ViewLogsDialog
1. Sidebar dates (last 30 days).
2. Read-only `SelectableText` viewer.
3. Open via menu, dismiss with ❌.
4. Widget test: select date shows lines.

### C10 – Menu Bar
1. Implement native menu (Quit, About).
2. “Setup Micro-breaks” → modal.
3. “View Logs” → modal.
4. Smoke test: all routes.

### C11 – Refinement
1. Error banner system (`SnackBar`).
2. Lint cleanup, golden screenshots.
3. Full regression test run.

### C12 – Packaging
1. App icon & name update.
2. Code-sign, notarize.
3. Release artifact in CI.

---

## 4. Code-Generation LLM Prompts

> Use **one prompt per micro-step** and keep tests green before moving on.

### Prompt 1 – Create Flutter Project
```text
You are a senior Flutter engineer.
**Task**: Initialize a new Flutter desktop project named `micro_break_manager` targeting macOS only.
Steps:
1. Run `flutter create -t desktop .` inside an empty repo.
2. Update `pubspec.yaml` with the stable channel constraint.
3. Ensure the default macOS launch window compiles and opens.
Provide the exact shell commands (no explanatory prose) and verify success by running `flutter run -d macos`.
```

### Prompt 2 – Add Core Dependencies
```text
You are continuing work in the same repo.
**Task**: Add the following packages to `pubspec.yaml` and run `flutter pub get`:
- `flutter_riverpod:^2.5.0`
- `path_provider:^2.1.3`
- `mocktail:^1.0.1`
- Update `dev_dependencies` with `flutter_test` and `lint`.
Also add an `analysis_options.yaml` enabling the `lints` core rules.
Output the diff of files changed.
```

### Prompt 3 – Set Up GitHub Actions CI
```text
You are the DevOps engineer.
**Task**: Create `.github/workflows/ci.yml` to run on `push` and `pull_request`.
Matrix: macos-latest.
Steps: checkout, set up Flutter `stable`, run `flutter pub get`, then `flutter test`.
Provide the YAML file contents only.
```

### Prompt 4 – Implement Data Models
```text
Write Dart models in `lib/models/`:

* `MicroBreakItem` — single `String text`.
* `MicroBreakList` — `String name`, `List<MicroBreakItem> items`.
* `LogEntry` — `DateTime start`, `DateTime end`, `String listName`, `String itemText`.

Add `fromTsv(String line)` and `toTsv()` for each.
Add unit tests in `test/models_test.dart` to ensure round-trip parsing works.
Return only the new Dart files and the test file.
```

### Prompt 5 – FileStorageService Skeleton
```text
Create `lib/services/file_storage_service.dart` with:

* `Future<List<MicroBreakList>> readLists()`
* `Future<void> saveList(MicroBreakList list)`
* `Future<List<LogEntry>> readDailyLog(DateTime date)`
* `Future<void> appendLogEntry(LogEntry entry)`
* `Future<void> purgeOldLogs({int keepDays = 30})`

Use `path_provider` to locate the app support directory.
Stub everything with TODOs and throw `UnimplementedError`.
Include unit test scaffolds using `mocktail` for the filesystem.
Return the code only.
```

### Prompt 6 – Implement `readLists()`
```text
Focus on `readLists()` in `FileStorageService`.
Implement reading each `.txt` file in the `lists/` directory, parsing lines into `MicroBreakItem`s.
If directory doesn’t exist, return `[]`.
Write unit tests (using a temporary directory) covering:
- No list dir → empty list.
- One file with three lines → proper model.
Return only modified code and tests.
```

### Prompt 7 – `RoundRobinManager` Logic
```text
Create `lib/services/round_robin_manager.dart`:

* Constructor takes `List<MicroBreakList>`.
* `Tuple<MicroBreakList, MicroBreakItem> nextItem()`
* `void cancelSelection()`

Maintain internal indices so each list and item round-robins.
Unit tests:
1. Two lists A(2 items) & B(1 item) produce order A1, B1, A2, B1…
2. `cancelSelection()` rolls back indices.

Provide implementation + tests.
```

### Prompt 8 – AppState Providers
```text
Set up Riverpod providers in `lib/providers.dart`:

* `storageProvider` (singleton `FileStorageService`)
* `microBreakListsProvider` (FutureProvider<List<MicroBreakList>>)
* `roundRobinProvider` (Provider<RoundRobinManager> based on lists)

Write an integration test with `ProviderContainer` that loads two dummy lists, asks `nextItem()` twice, and verifies order.

Return modified Dart files and test.
```

*Replicate this pattern for every remaining micro-step, keeping tests green throughout.*

---

**Happy coding!**
