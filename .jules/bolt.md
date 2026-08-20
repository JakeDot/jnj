## 2025-05-18 - Avoid List.unmodifiable in Dart Getters
**Learning:** `List.unmodifiable(iterable)` in Dart creates a full O(N) copy of elements into a new array every time it is evaluated. Calling `List.unmodifiable` inside getters that are accessed repeatedly (e.g., inside `ListView.builder` or `build` loops) creates O(N^2) allocations and time complexity per render frame.
**Action:** Use `UnmodifiableListView(list)` from `dart:collection` as a cached view instead of `List.unmodifiable`.
