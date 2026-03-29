# MKMapSnapshotter Benchmark Results

## Results

| Metric | Test 1 (1×, 300px) | Test 2 (8×, 300px) | Test 3 (5×, 300px) | Test 4 (10×, 150px) | Test 5 (10×, 150px) | Test 6 (5×, 150px) |
|---|---|---|---|---|---|---|
| **End-to-end** | **336.4s** | **n/a** | **220.9s** | **244.5s** | **242.9s** | **243.9s** |
| Snapshot batch | 331.5s | n/a | 217.9s | 243.5s | 239.9s | 241.0s |
| Workout fetch | 4.8s | 3.3s | 2.9s | 0.9s | 2.9s | 2.8s |
| Avg snapshot gen | 0.2s | 1.5s | 0.9s | 2.2s | 2.2s | 1.0s |
| Avg loc fetch | 0.1s | 0.2s | 0.1s | 0.1s | 0.1s | 0.1s |
| Avg drawing | 4.8ms | 3.5ms | 3.6ms | 1.1ms | 1.3ms | 1.2ms |
| Throughput | 4.3/s | ~5.5/s | 5.6/s | 4.6/s | 4.6/s | 4.6/s |

- 1,046 workouts with route data
- 2,723,040 total location points (avg 2,603 per workout)

## Test Configurations

**Test 1 (baseline: 336.4s)**
- Concurrency: 1 (sequential)
- Image size: 300×300
- Map type: `.standard`
- Downsample: none (all points)
- Route filter: sequential N+1
- Line width: 3pt

**Test 2 (n/a end-to-end — export bug)**
- Concurrency: 8
- Image size: 300×300
- Map type: `.standard`
- Downsample: 200 points
- Route filter: parallel N+1, bounded at 10
- Line width: 3pt

**Test 3 (best: 220.9s)**
- Concurrency: 5
- Image size: 300×300
- Map type: `.standard`
- Downsample: 200 points
- Route filter: parallel N+1, bounded at 10
- Line width: 3pt

**Test 4 (244.5s)**
- Concurrency: 10
- Image size: 150×150
- Map type: `.mutedStandard`
- Downsample: 120 points
- Route filter: removed (lazy check)
- Line width: 2pt

**Test 5 (242.9s)**
- Concurrency: 10
- Image size: 150×150
- Map type: `.mutedStandard`
- Downsample: 120 points
- Route filter: parallel N+1, bounded at 10
- Line width: 2pt

**Test 6 (243.9s)**
- Concurrency: 5
- Image size: 150×150
- Map type: `.mutedStandard`
- Downsample: 120 points
- Route filter: parallel N+1, bounded at 10
- Line width: 2pt

## Key Findings

**What made Test 3 the fastest:**
- Concurrency 5 hit the sweet spot — enough parallelism without starving MKMapSnapshotter's shared tile cache/renderer
- Per-item snapshot time was 0.9s vs 2.2s at concurrency 10 — less contention meant each snapshot got more resources
- Throughput was 5.6/s vs 4.6/s — the lower per-item cost more than compensated for fewer concurrent tasks
- Tile cache was likely warmer (first parallel run after sequential, which may have primed the cache)

**What didn't matter:**
- Image size (150px vs 300px) — no meaningful impact since the bottleneck is tile fetching, not rendering
- `.mutedStandard` vs `.standard` — same tiles, different styling
- Downsample 120 vs 200 — only affects drawing which is ~1ms either way

**Bottleneck:** `MKMapSnapshotter.start()` dominates at ~97% of per-item time. It fetches and renders map tiles internally, and shares resources across concurrent instances. Higher concurrency increases contention without proportional throughput gains.

## Technical Architecture

### Concurrency Model

The app uses Swift Concurrency (`async/await`) throughout. No GCD dispatch queues or `OperationQueue` in app code — GCD only exists inside Apple's frameworks (HealthKit query callbacks, MKMapSnapshotter internals).

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so the view model and stats classes are implicitly `@MainActor`. UI state mutations happen on the main actor. Heavy work runs off-main via `nonisolated` functions and `TaskGroup` child tasks.

### Pipeline Phases

The pipeline runs in three sequential phases:

#### Phase 1: HealthKit Authorization
- Single `async` call to `HKHealthStore.requestAuthorization(toShare:read:)`
- ~100ms (mostly no-op after first grant)

#### Phase 2: Workout Fetch + Route Filtering
- **Step A:** Single `HKSampleQuery` fetches all workouts (one query, returns ~2000+ workouts)
- **Step B:** Parallel N+1 route filter — for each workout, an `HKSampleQuery` checks if associated `HKWorkoutRoute` samples exist. HealthKit has no predicate to filter workouts by route existence, so this per-workout check is unavoidable.
- Route filter uses a `ThrowingTaskGroup` with a sliding-window of 10 concurrent tasks to avoid thread explosion from HealthKit's GCD-backed callbacks.
- Results are collected with their original indices and re-sorted to preserve date ordering.

#### Phase 3: Snapshot Generation (batch)
- A `TaskGroup` with a sliding-window of `maxConcurrency` (currently 5) processes each workout.
- Each child task is `static nonisolated` and only captures `Sendable` services (`HealthKitService`, `MapSnapshotService`, `Logger`) — no `self` capture avoids MainActor isolation issues.
- Per-workout, each child task does:
  1. **Fetch locations** — `HKSampleQuery` gets `HKWorkoutRoute` samples for the workout, then `HKWorkoutRouteQuery` streams `CLLocation` batches for each route. Batches are accumulated and returned via `withCheckedThrowingContinuation` with a `hasResumed` guard to prevent double-resume crashes.
  2. **Downsample coordinates** — Raw locations (avg 2,603 points) are reduced to 120 evenly-spaced points. First and last points are always preserved.
  3. **Calculate region** — Single pass over coordinates to find bounding box, expanded by 1.3× for padding.
  4. **MKMapSnapshotter.start()** — Apple's async API renders map tiles for the region at the configured size. This is the bottleneck (~97% of per-item time). Internally uses a shared tile cache and renderer that degrades under concurrent load.
  5. **Draw route overlay** — `UIGraphicsImageRenderer` draws the polyline on top of the snapshot image. Runs synchronously on whichever thread the child task is on.
- As each child task completes, the `for await` loop runs on the MainActor to apply results (images, timings, stats) to `@Observable` state, which triggers SwiftUI grid updates.

### HealthKit Bridge Pattern

All HealthKit queries use callback-based APIs (`HKSampleQuery`, `HKWorkoutRouteQuery`) bridged to `async/await` via `withCheckedThrowingContinuation`. The callbacks fire on HealthKit's internal GCD queues, then resume the Swift Concurrency continuation. `HKWorkoutRouteQuery` delivers locations in multiple batches — only the final batch (where `done == true`) resumes the continuation.

### Thread Safety

- `HealthKitService` and `MapSnapshotService` are `Sendable` final classes with no mutable state — safe to use from any isolation context.
- `BenchmarkStats` and `WorkoutMapViewModel` are `@MainActor`-isolated `@Observable` classes — all mutations happen on the main actor.
- `TaskGroup` child tasks never access MainActor-isolated state. Results flow back through the task group's return type and are applied in the `for await` loop which runs on MainActor.
- `HKWorkoutRouteQuery` callback uses a `hasResumed` flag to guard against double continuation resume if HealthKit delivers an error after partial data.
