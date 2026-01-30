# Progress Plan

## Phase 1: Apply Refactor Recommendations

Goal: Align event JSON handling, tighten type safety, harden input validation, and reduce noisy layout updates.

### TASK 1: Unify event JSON schema (single source of truth)

- Update `lib/src/models/event.dart` to parse/serialize the canonical event shape (`newSize`, `newPosition`, `newState`, `fromIndex`, `toIndex`, `child`).
- Keep backward-compatibility for legacy keys (`size`, `position`, `state`, `from`, `to`) where feasible.
- Implement `addChild` parsing and serialization so `Event` and `JsonParser` agree.
- Update tests in `test/models/event_test.dart` to match the new schema.

### TASK 2: Tighten types at API boundaries

- Change `RenderPipeline.processFromComponents` to accept `List<Event>` instead of `List<dynamic>`.
- Change `Renderer.resultsFromJson` to accept `List<Map<String, dynamic>>` instead of `List<dynamic>`.
- Update any affected tests to satisfy new static types.

### TASK 3: Strengthen input validation

- Validate tree root existence and child references in `JsonParser._parseTree` with clear `FormatException` messages.
- Add index range checks and duplicate ID checks in `Engine._processAddChild` before mutating the tree.

### TASK 4: Stabilize layout updates for floating-point noise

- Use an epsilon comparison in `LayoutCalculator.recalculateLayout` to avoid marking layouts dirty for negligible float deltas.
- Keep existing `Size`/`Position` equality operators intact to avoid wide behavioral change.

## Execution Notes

- Apply tasks in order and keep changes minimal.
- Ensure tests compile with updated signatures and schemas.
