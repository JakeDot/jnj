## 2025-05-18 - Avoid List.unmodifiable in Dart Getters
**Learning:** `List.unmodifiable(iterable)` in Dart creates a full O(N) copy of elements into a new array every time it is evaluated. Calling `List.unmodifiable` inside getters that are accessed repeatedly (e.g., inside `ListView.builder` or `build` loops) creates O(N^2) allocations and time complexity per render frame.
**Action:** Use `UnmodifiableListView(list)` from `dart:collection` as a cached view instead of `List.unmodifiable`.

## 2025-05-19 - Precompute String Interpolations & Search Keys in Model Constructors
**Learning:** Evaluating string getters (e.g. `shortRef => '$repo#$number'`) or converting strings during list filtering (`title.toLowerCase()`, `number.toString()`, `author.toLowerCase()`) inside `ListView.builder` or live text search listeners causes thousands of transient string allocations per keystroke/scroll frame.
**Action:** Precompute immutable fields (`shortRef`) and a lowercased `searchKey` in model constructor initializer lists to perform zero-allocation string matching during search and UI rendering.
