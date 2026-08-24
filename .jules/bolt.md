## 2025-05-18 - Avoid List.unmodifiable in Dart Getters
**Learning:** `List.unmodifiable(iterable)` in Dart creates a full O(N) copy of elements into a new array every time it is evaluated. Calling `List.unmodifiable` inside getters that are accessed repeatedly (e.g., inside `ListView.builder` or `build` loops) creates O(N^2) allocations and time complexity per render frame.
**Action:** Use `UnmodifiableListView(list)` from `dart:collection` as a cached view instead of `List.unmodifiable`.

## 2025-05-19 - Precompute Search Keys on Immutable Data Models
**Learning:** Dynamically calling `title.toLowerCase()`, `number.toString()`, and `author.toLowerCase()` on every item in `ListView` filtering on every single keystroke creates O(N) string allocations per frame during live search.
**Action:** Precompute and store `searchKey` on model instances during constructor initialization to allow zero-allocation O(1) string matching (`item.searchKey.contains(query)`).
