# Shader Performance Profiling Report

**Date:** 2026-06-09 · **Machine:** Apple M3 Max, macOS 26.5 (25F71), 120 Hz ProMotion display, DPR 2.0
**Flutter:** 3.38.5 stable · **Renderer:** Impeller/Metal (engine default for macOS; no `FLTEnableImpeller` override present) · **Mode:** profile
**Window:** 800×1042 logical (3.33 Mpx physical). "Card size" below = 480×640 logical (1.23 Mpx physical).

Targets: `iridescent_liquid_wrap.frag`, `iridescent_liquid.frag`, `fur_planar_mask.frag`, plus a default-parameters survey of all 38 registered shaders.

> **Update 2026-06-10:** the recommended optimizations were applied and re-measured — every saturating workload below now holds a locked 120 fps at full window. §1–§10 are kept as the historical record; see **§11** for the changes, post-optimization numbers, and visual review.

---

## 1. Executive summary

**At card sizes on Apple-Silicon-class hardware, none of the three shaders is a problem** — all hold a locked 120 fps with ≤2 ms raster-thread time and the GPU running at reduced clock. The risks are at large render areas, with specific mechanisms, and (by extrapolation) on weaker GPUs:

| # | Shader | Bottleneck | Evidence (full window, 3.33 Mpx, 120 Hz budget = 8.33 ms) |
|---|--------|-----------|------------------------------------------------------------|
| 1 | fur_planar_mask | **Active tap wavelets**: ≈ +1.3 ms/frame per click | 0 clicks = 10.7 ms/frame (88–94 fps) → 5 clicks = **15.8 ms/frame (63 fps)** |
| 2 | iridescent_liquid_wrap | **Contour edge-distance raycast** (32 dirs × ≤12 mask taps), cost scales with mask coverage | contour ON = 10.9 ms (92 fps); contour OFF = **fits 120 fps**; full-coverage child = **14.7 ms (68 fps)**, sparse text child = 8.5 ms |
| 3 | fur_planar_mask | **Per-step mask sampling floor** (5 texture taps × 64 steps, runs before the early-`continue`) | drop 4/5 taps → fits 120 fps (and 0.22 ms GPU at card size, −96%); halve RAY_STEPS → fits 120 fps; ALU stubs (lighting, gradient, noise) save ≈ nothing |
| 4 | iridescent_liquid_wrap | **Chromatic aberration = 3× full domain-warp** (≈97 snoise/px total) | single shared warpMap → **fits 120 fps** (≥2.6 ms saved); 4→2 fbm octaves → fits |
| 5 | iridescent_liquid (fill) | No bottleneck on this hardware — **never saturates, even full-window** | all fill variants lock 120 fps at 3.33 Mpx; cost is ~92 % noise tree (see §6.3) |
| 6 | (survey find) kuwahara | Only non-target shader that saturates full-window | 9.6 ms/frame (104 fps) |
| 7 | all wraps | **Child re-capture every frame** (`toImageSync`): CPU floor ~1–1.6 ms raster-thread per wrap instance, even for a passthrough shader | passthrough wrap = 0.6–1.2 ms raster vs fill = 0.3 ms; survey: every wrap ≈ 1.9–2.1 ms vs every fill ≈ 0.9 ms |

Worst measured case (fur, 5 clicks, full window) still fits a 60 Hz budget (16.7 ms) **on an M3 Max**. Mid-tier mobile GPUs are roughly an order of magnitude slower; anything that saturates this machine should be assumed to miss 60 fps at far smaller areas there. Mobile measurement was out of scope (macOS only, per request).

---

## 2. Methodology

Four instruments, because no single one is sufficient on macOS/Metal:

1. **FrameTiming matrix** (`test/lib/bench/`): automated runner mounts each config, discards 90 warmup frames, measures 360 frames via `SchedulerBinding.addTimingsCallback`, reports build/raster percentiles, fps, jank. Deterministic **virtual time** (`t = frame/60`, `ShaderAnimationMode.implicit`) so every run/variant samples identical uniform trajectories.
2. **GPU utilization sampling** (`bench_logs/gpu_sample.sh`): IORegistry `Device Utilization %` while one config runs in HOLD mode.
3. **Metal System Trace** (`bench_logs/gpu_trace.sh`): `xctrace` attached to the held app; `metal-gpu-intervals` reduced to per-process GPU busy ms/s (`parse_trace.py`).
4. **Saturated throughput** (`BENCH_FULLSIZE=true`): every config re-targeted at the full window so the GPU saturates; steady-state fps ⇒ ms/frame.

### 2.1 Two measurement traps these instruments exist to defeat

- **Async GPU**: `FrameTiming.rasterDuration` is raster-*thread CPU* time. Metal executes asynchronously, so at card sizes *every* shader variant measures ~1.6 ms regardless of GPU cost (even deleting all noise math changed nothing). GPU cost only appears in FrameTiming once it exceeds the frame budget (backpressure → fps drop, p90/jank spikes). Raster-thread numbers measure the *widget machinery*, not the shader.
- **GPU DVFS**: the GPU governor downclocks until busy ≈ 66 % of frame time, so sub-budget workloads of very different sizes all read "~66 % util / ~5.5 ms busy" at *different unknown clocks* (`prod.iwrap.480` ≈ `prod.iliq.480` ≈ `prod.fur.480` ≈ kuwahara ≈ liquid_patina ≈ 5.5 ms). Absolute GPU-interval durations are only comparable between configs in the same clock regime. **Saturated throughput (fps at full window) is the clean comparator** and is what §1/§6 deltas use; unsaturated trace deltas are reported as conservative lower bounds.

### 2.2 Shader bisection

20 instrumented variants under `test/shaders/profiling/bench_*.frag` (never registered in the published package), each a byte-copy of the production shader with one mechanism stubbed/reduced. Attribution = base − variant at identical size/child/time. All variants passed the runtime SkSL validation gate (`BENCH_VALIDATE_ONLY`), which is the only reliable compile check (build success does not validate the runtime transpile).

**Content-coupling caveat:** a stub can change the *image*, which changes early-exit behavior (fur's `transmittance` break, mask early-outs). `bench.fur.noedgelean` and `bench.fur.noise_const` alter fur density and are flagged where used; conclusions lean on the converging evidence of multiple variants, never one stub alone.

---

## 3. Harness verification (gates)

| Gate | Result |
|---|---|
| V1 repeatability | 82 configs × 3 observations (2 forward passes + 1 reversed): median CV of raster p50 = **2.1 %**. Sub-millisecond configs show higher *relative* CV (absolute spread ≤0.6 ms); saturated configs ±5 %. |
| V2 baseline sanity | `base.empty` 0.3–0.9 ms raster ≪ 8.33 ms budget; perlin fill 0.45 ms GPU; passthrough wrap 0.15 ms GPU. |
| V3 known-ratio | NUM_DIRS 32→16→8 monotone: 10.91 → 9.63 → 8.88 ms/frame. Fur steps 64→32 crosses under budget as predicted. Exact 2× ratios are masked by DVFS in the unsaturated regime (documented above). |
| V4 parity | Hand-rolled uniform callbacks ≡ production widgets: iwrap 1.627 vs 1.626 ms, iliq 0.882 vs 0.871, fur 1.558 vs 1.645 (≤5 %). Validates every variant binding. |
| V5 instrument cross-check | Metal-trace GPU ms and IOReg utilization rank-order identically across 12 spot configs (0.15 ms↔19 % … 5.6 ms↔66–69 % … saturated↔100 %). |
| V6 order invariance | Forward vs reversed runs match within V1 noise at card size. Backpressured (full-window) configs are order/thermal sensitive in FrameTiming — expected; the saturated sweep is used for those instead. |

---

## 4. The machinery tax (applies to every wrap, any shader)

From the FrameTiming matrix (card size, 120 Hz):

- **Fill shaders**: ~0.9 ms raster-thread, ~0.55 ms build. CustomPainter path is cheap.
- **Wrap shaders**: ~1.9–2.1 ms raster-thread regardless of shader — the `AnimatedSamplerRepaint` child capture (`toImageSync`) runs **every frame even for a static child**. The passthrough-shader wrap isolates this: pure capture+encode with zero shader math costs 0.6–1.2 ms raster CPU (plus it scales with window size: 1.1 ms at full).
- **Uniform upload is a non-issue**: 93 setFloats per frame ≈ +0.2 ms build (`base.iwrap.tiny` vs `base.empty`).
- **Multi-instance**: 9 simultaneous animating iwrap instances in a 3×3 grid = 2.4 ms raster CPU total (sub-linear; smaller area each). CPU-side, ~4 full-card animating wraps fit a 120 Hz budget; ~9 fit 60 Hz.

---

## 5. All-shader survey (defaults, card size, image child for wraps)

Mean of 3 observations, sorted by raster p50. **This column is CPU-side cost** (see §2.1); the GPU column, where measured, is from the Metal trace at the DVFS operating point. Survey shaders were driven deterministically; dissolve-style wraps got a ping-pong progress sweep so the effect is exercised mid-transition.

| shader (survey id) | kind | raster p50 ms | GPU note |
|---|---|---|---|
| smoke_radial | wrap | 2.11 | 0.6 ms GPU at card size — CPU number is capture tax, GPU trivial |
| smoke_tap*, burn_tap*, dither, pixel_dissolve_tap*, pixel_dissolve, peel, smoke, slurp_tap*, pixel_dissolve_radial, turbulence_wrap, burn_radial, ripples, taplets*, burn | wrap | 1.92–1.98 | all dominated by capture tax |
| crepuscular_rays | wrap | 1.81 | ~4 ms GPU @DVFS; fits 120 fps full-window |
| iridescent_liquid (wrap) | wrap | 1.71 | **saturates full-window: 8.9 ms/frame** (text child) |
| kuwahara_wrap | wrap | 1.70 | **saturates full-window: 9.6 ms/frame** — only non-target hot shader |
| fur_mask | wrap | 1.65 | **saturates full-window: 11.1 ms/frame** |
| gradient fills (simplex/perlin/voronoi/fbm/turbulence/voronoise ± radial) | fill | 0.87–0.97 | trivial GPU |
| metal_smoke | fill | 0.93 | 2.1 ms GPU @DVFS; fits full-window |
| fur (fill)* | fill | 0.91 | ~5.5 ms GPU @DVFS; fits full-window |
| grit, liquid_patina, perlin, smarble*, iridescent_liquid_fill, turbulence, fbm_radial, grit_radial | fill | 0.74–0.90 | liquid_patina 5.5 ms GPU @DVFS, still fits full-window |

`*` measured in **passive default state** — tap/drag-activated paths (tappables, marble smudges, fur wavelets) not exercised; their active cost is not in this table. The fur deep-dive (§6.2) shows wavelets add ~+1.3 ms/click at full window, so treat starred rows as lower bounds under interaction.

**Survey conclusion:** no hidden monster among the other 35 shaders. Kuwahara is the only additional shader that saturates the GPU full-window and is a candidate for a future deep-dive.

---

## 6. Deep-dive attribution (saturated full-window deltas unless noted)

Base references: `iwrap` 10.9 ms/frame · `fur` 10.7 ms/frame · `iliq` fits (≤8.3). "fits" = variant reached the 120 fps vsync ceiling, so its true saving ≥ (base − 8.33 ms); the ceiling caps what we can see.

### 6.1 iridescent_liquid_wrap — sum of two expensive mechanisms

| variant / sweep | ms/frame | delta vs base | mechanism |
|---|---|---|---|
| base (circle child, contour 0.5) | 10.91 | — | |
| contour = 0 (uniform gate) | fits | **≥ −2.6** | entire edge-distance raycast off |
| contour = 1.0 | 10.89 | ±0 | cost is gate-shaped, not magnitude-shaped ✓ |
| edgeBandPx 16→48 | 10.86 | ±0 | tap-count-bound, not search-radius-bound ✓ |
| child_rect (100 % coverage) | **14.73** | **+3.8** | interior pixels: all 32 rays run all 8 coarse steps — raycast worst case |
| child_text (~15 % coverage) | 8.48 | −2.4 | most pixels exit at the mask check |
| NUM_DIRS 32→16 | 9.63 | −1.3 | raycast directions |
| NUM_DIRS 32→8 | 8.88 | −2.0 | |
| NUM_COARSE 8→4 | 9.55 | −1.4 | raycast depth |
| 1 warpMap instead of 3 | fits | **≥ −2.6** | chromatic aberration = 2 extra full domain-warps (≈48 snoise/px) |
| bump warpShape stubbed | 8.85 | −2.1 | the 4th warpShape eval (≈24 snoise/px) |
| fbm 4→2 octaves | fits | ≥ −2.6 | per-octave cost across all warp evals |
| fbm → 0 | fits | ≥ −2.6 | total noise floor |

Reading: cost ≈ noise/warp component (~comparable to the fill) **plus** raycast component that scales with mask coverage (range 8.5 → 14.7 ms across children). Both are individually reducible below budget.

### 6.2 fur_planar_mask — texture-fetch machine, ALU is free

| variant / sweep | ms/frame | delta | mechanism |
|---|---|---|---|
| base (circle child, 0 clicks) | 10.68 | — | |
| clicks = 1 | 11.95 | +1.3 | wavelet eval + wavelet gradient (4 extra `totalWavelet` per lit step) |
| clicks = 5 | **15.82** | **+5.1** | ≈ linear per click |
| child rect / text / noise80 | 10.6–10.7 | ±0 | cost is coverage-independent — the 5 mask taps/step run before the early-`continue` ✓ |
| RAY_STEPS 64→32 (span kept) | fits | ≥ −2.4 | per-step scaling confirmed |
| RAY_STEPS 64→16 | fits | ≥ −2.4 | |
| 4 gradient mask taps dropped† | fits | ≥ −2.4 | at card size: 5.55 → **0.22 ms GPU (−96 %)** |
| gradient ALU stubbed | 10.14 | −0.5 | `fastGradient` noise+sin chains ≈ noise |
| lighting stubbed | 11.45 | ±0 (noise) | 4-light dot/smoothstep ALU is free |
| proceduralNoise → const† | fits | (content-coupled) | |

† changes the rendered content (fur density → early-termination behavior); direction corroborated by the independent steps/ALU variants.

Reading: fur cost = (5 mask-texture taps + dependent lean math) × 64 steps × every pixel, plus wavelets when clicks are live. Lighting, gradient and noise ALU are hidden behind texture latency.

### 6.3 iridescent_liquid (fill) — fine on this class of hardware

Never saturates at 3.33 Mpx. At card size (Metal trace, same DVFS operating point — treat as shares):

| variant | GPU ms/frame | share removed |
|---|---|---|
| base | 5.63 | — |
| 1 warpMap instead of 3 | 3.38 | **−40 %** (chromatic aberration) |
| fbm 4→2 octaves | 4.12 | −27 % |
| fbm → 0 | 0.44 | **−92 %** (the noise tree is essentially the whole shader) |

---

## 7. Recommended optimizations (ranked, each prototyped by a measured variant)

The variant **is** the prototype — the win column is measured, not estimated. Visual risk can be reviewed by holding the variant: `BENCH_HOLD=<id> flutter run --profile -t lib/bench/main_bench.dart`.

| # | Change | Measured win | Risk / notes |
|---|---|---|---|
| 1 | **fur: hoist the mask gradient out of the ray loop** — compute it once per pixel at the plane projection instead of per step (surface is planar; the per-step gradient barely changes). Not a quality trade: same information, 256 taps → 4. | the per-step-tap mechanism is ≥2.4 ms at full window; −96 % GPU at card size when removed | low; needs care at grazing angles. The `noedgelean` variant shows the ceiling, the real fix keeps the lean. |
| 2 | **iwrap: share one warpMap across RGB** and approximate chromatic aberration by offsetting the palette-index scalar per channel instead of re-running the warp | ≥2.6 ms (full window); −40 % of fill GPU | aberration becomes approximate; keep exact path behind a quality param |
| 3 | **iwrap: NUM_DIRS 32→16** (optionally with slightly higher `uEdgeSmoothness` default) | −1.3 ms; 32→8 = −2.0 ms | mild radial "wrinkle" in the contour field; visually inspect via HOLD |
| 4 | **fur: cap or stagger wavelet clicks** (maxClicks 5→3, or skip `waveletGradient` for clicks older than ½ lifetime) | up to −2.6 ms at full window | interaction richness vs cost; +1.3 ms/click measured |
| 5 | **fur: RAY_STEPS 64→32 with RAY_STEP ×2** | ≥2.4 ms | visible slice-coarsening at 16; 32 is the candidate — review via HOLD side-by-side |
| 6 | **iwrap: fbm 4→2 octaves** in the warp (or only in the two outer fbm2 layers) | ≥2.6 ms | subtle loss of fine grain in the liquid texture |
| 7 | **ShaderWrap: skip child re-capture when the child layer hasn't repainted** (cache the `toImageSync` result in `animated_sampler_repaint.dart`) | ~1 ms raster CPU per wrap instance per frame; benefits all 17 wrap shaders | architectural; needs a child-repaint dirty bit |
| 8 | (future) kuwahara deep-dive | — | only other full-window saturator (9.6 ms) |

Not recommended: anything targeting fur lighting/gradient/noise ALU (measured ≈ free), `edgeBandPx` tuning (no effect), or fill-shader work for desktop targets (never saturates).

---

## 8. Reproduction

```bash
cd test
# Runtime shader validation (after ANY .frag edit — build success is not enough):
flutter run -d macos -t lib/bench/main_bench.dart --dart-define=BENCH_VALIDATE_ONLY=true
# Full FrameTiming matrix (~6 min/pass; prints markdown + CSV, exits itself):
flutter run -d macos --profile -t lib/bench/main_bench.dart --dart-define=BENCH_REPEAT=2
flutter run -d macos --profile -t lib/bench/main_bench.dart --dart-define=BENCH_REVERSE=true
# Subsets / one config held for instruments:
flutter run -d macos --profile -t lib/bench/main_bench.dart --dart-define=BENCH_FILTER=fur
flutter run -d macos --profile -t lib/bench/main_bench.dart --dart-define=BENCH_HOLD=prod.fur.clicks5
# Saturated throughput variant of any config: add --dart-define=BENCH_FULLSIZE=true (ids gain ".fs")

# GPU instruments (profile bundle must exist: flutter build macos --profile -t lib/bench/main_bench.dart)
BIN="test/build/macos/Build/Products/Profile/Test Demos.app/Contents/MacOS/Test Demos"
bench_logs/gpu_sample.sh prod.iwrap.480 "$BIN"   # IOReg utilization + hold fps
bench_logs/gpu_trace.sh  prod.iwrap.480 "$BIN"   # Metal System Trace → per-process GPU ms/s
```

Environment discipline: plugged in, `caffeinate -dis`, single display, don't move/resize the window, no debug mode (the runner suppresses results in debug). Note: `xctrace --launch` resolves the app through LaunchServices and can launch a **stale app copy** (this burned an hour) — `gpu_trace.sh` launches the exact binary and attaches instead.

### Manual Xcode GPU Frame Capture (per-draw limiter stats / cost-per-line)

For ALU-vs-texture limiter percentages and per-line shader cost (not automatable):
1. `flutter build macos --profile -t lib/bench/main_bench.dart`, `open test/macos/Runner.xcworkspace`
2. Edit Scheme → Run: Build Configuration = Profile; Options → GPU Frame Capture = Metal; Arguments → Environment Variables: `BENCH_HOLD=<configId>`
3. Run → wait ~10 s → Debug → Capture GPU Workload → select the render pass → **Profile** → read per-draw GPU time, limiter occupancies, per-line costs.

## 9. Artifacts

- Harness: `test/lib/bench/` (runner, configs, survey, hand-rolled uniforms, stats) — `flutter run -t lib/bench/main_bench.dart`
- Variants: `test/shaders/profiling/bench_*.frag` (20 files, registered only in the test app)
- Raw data: `bench_logs/` — `results_fwd.csv` (164 rows), `results_rev.csv` (82), `gpu_sweep.log` (IOReg), `gpu_trace_sweep.log` (Metal trace), `fullsize_sweep.log` (saturated throughput), `full_fwd.log`/`full_rev.log`/`smoke.log` (run logs)

## 10. Limitations

- macOS / M3 Max / Impeller-Metal only (per scope). Mobile GPUs are ~an order of magnitude slower; treat "fits 120 fps here" as "needs verification there", especially anything within 2× of this machine's budget.
- Saturated deltas marked "fits" are vsync-capped lower bounds.
- Unsaturated GPU-interval comparisons are DVFS-confounded (documented in §2.1); used only as shares/bounds.
- Interaction-gated survey rows measured passive (flagged `*`).
- `bench.fur.noedgelean` / `bench.fur.noise_const` change rendered content; conclusions rest on converging independent variants.

---

## 11. Optimizations applied (2026-06-10)

### 11.1 Changes

Production shaders (uniform layouts unchanged — no consumer-facing API change):

1. **fur_planar_mask.frag — mask field hoisted out of the ray loop** (rec #1). The surface is exactly planar, so the ray is intersected with the *mid-shell* plane analytically before the loop (`rayDir.z == 1`, one subtraction); the 4 mask-gradient taps + the strand-root tap are fetched once per pixel instead of once per step (**320 taps → 5 taps/pixel** away from mask edges). The loop keeps the height-dependent lean (`h01² · edgeStrength · uEdgeLeanStrength`) as pure ALU on the hoisted values. Mid-shell sampling halves the xy-drift error at grazing angles vs sampling at the shell top.
   **Edge-band exception (follow-up fix):** the *base-trace* sample stays per-step wherever `edgeStrength > 0.001`. The inward lean grows with height, so hair rooted inside the mask overhangs the boundary at the tip — the "spill-over" that sells the 3D effect. A single fixed-lean sample replaces that overhang with a hard cut at the region edge (caught in review on a real-edge child; the bench children couldn't show it, see §11.3). The band is bounded by the ±8 px gradient stencil — the same stencil that bounded the spill reach before the hoist — so only a thin ring of pixels pays 1 tap/step; everywhere else stays at 5 taps/pixel.
2. **fur_planar_mask.frag — wavelet field hoisted** (rec #4). `totalWavelet` + `waveletGradient` are evaluated once per pixel at the hoisted plane position instead of per step (≈320×C → ≤5×C wavelet evals; displacement becomes constant along each strand). The gradient (specular shimmer) additionally sums only clicks younger than ~½ lifetime (`decay ≥ √0.001`); displacement keeps the full lifetime.
3. **FurPlanarMaskShaderWrap — interactive `maxClicks` 5 → 3** (rec #4). The shader keeps 5 uniform slots (`shaderClickSlots`); a 4th simultaneous interactive tap recycles the oldest ripple. Externally supplied `touchPoints` can still drive all 5 (the bench does).
4. **iridescent_liquid_wrap.frag — contour raycast** (rec #3 + interior early-out). (a) Before the ray fan, 8 probe taps on a ring of radius `uEdgeBandPx`: if all are inside the mask the true edge distance exceeds the band and the field saturates to 0 — return immediately (8 taps replace the full fan for deep-interior pixels, the exact mechanism behind the +3.8 ms full-coverage worst case). (b) `NUM_DIRS` 32 → 16. (c) `NUM_COARSE` 8 → 4 with the search span kept. `edgeSmoothness` default 0.25 → 0.35 to dissolve the residual 16-ray angular wrinkles.
5. **iridescent_liquid_wrap.frag + iridescent_liquid.frag — chromatic aberration restructured** (rec #2). One shared `warpShape` eval serves all three channels (`warpMap` → cheap per-channel `warpPalette` tail); the visible rainbow dispersion lives in the per-channel stripe phases, which are kept. In the wrap, the bump-term `warpShape(2p)` eval is also reused for the color path when `uContour < 0.001` (bit-exact there, since `warpUV == 2p`); in the fill that dedupe is unconditional and exact. Fill noise tree: ≈97 → ≈25 snoise/px.

Deliberately **not** applied: fur `RAY_STEPS` 64→32 (rec #5 — hoists already clear the budget; would add visible slice-coarsening), fbm 4→2 octaves (rec #6 — fine-grain loss, not needed on this hardware class), `NUM_DIRS`→8, the per-capture distance-field texture (architectural), a quality param for the exact 3-warp aberration path (defaults never needed it; add if a "max quality" tier appears), and rec #7 (child re-capture caching) which is unaddressed and still costs ~1 ms raster CPU per wrap instance.

### 11.2 Post-optimization measurements

Same harness, window restored to 800×1042 logical (3.33 Mpx), saturated full-window mode, `BENCH_REPEAT=2` (both passes agreed; pass-2 values shown). **Old = the `bench.*.base` byte-copies of the pre-optimization shaders, measured in the same run** as the new production code, so the comparison shares clock/thermal conditions. The old anchors reproduce §6's numbers (92↔10.7 ms, 63↔15.8 ms, 92↔10.9 ms, 68↔14.7 ms), validating the environment.

| workload (full window) | old | new |
|---|---|---|
| fur, circle child, 0 clicks | 90 fps (~10 ms/frame) | **120 fps (vsync-locked)** |
| fur, 5 active clicks | **62 fps (15.4–15.9 ms)** | **120 fps** |
| fur, full-coverage / sparse / noise80 children | ≈ base (coverage-independent) | 119–120 fps |
| fur, real-edge glyph child (spill-over band active) | 100 fps | **120 fps** (p50 raster 2.0 ms) |
| iwrap, circle child, contour 0.5 | 92 fps (~10.9 ms) | **120 fps** |
| iwrap, full-coverage rect child | **68 fps (~14.7 ms), raster p90 28–37 ms** | **120 fps, raster p90 2.3 ms** |
| iwrap contour=1 / edgeBand 48 / 3×3 grid | 92 fps / 92 fps / — | all 120 fps |
| iliq fill (every config) | 119–120 fps (never saturated) | 120 fps |

The fill never saturated this GPU before or after; its change is mobile insurance — the dedupe + shared chromatic remove ~74 % of its snoise tree analytically, consistent with §6.3's measured warp1 (−40 %) and fbm→0 (−92 %) bounds.

### 11.3 Visual review

20 deterministic snapshots (new `BENCH_SNAPSHOT` mode, below) at identical virtual times t = 2.0 s and 7.3 s, old vs new: fur ±5 clicks, iwrap circle + full-coverage rect, iliq fill — **indistinguishable in side-by-side review** (`bench_logs/snapshots/`). This matches expectation: the iwrap interior early-out is exact wherever the mask has no sub-45° notch; the fill dedupe is bit-exact for the G channel; the aberration keeps the per-channel stripe phases that carry the visible fringing. The young-click gradient cutoff (½ lifetime ≈ 2.0 s at default decay 1.76) is not exercised by the bench clicks (ages cycle 0.3–1.8 s); on real taps it fades ripple shimmer over the second half of a ~3.9 s lifetime, by design.

**A/B blind spot, found the hard way:** the fur snapshots above could not catch mask-edge regressions. Fur's default `maskColor` is black, and transparent capture regions also read rgb(0,0,0) — so every shape-on-transparent bench child masks as "fur everywhere" and exercises no real edge. The initial fully-hoisted base-trace shipped a real regression (spill-over replaced by a jagged cut, caught in use on a real child) that all 8 fur snapshot pairs missed. Fixed by the §11.1 edge-band exception and verified on a new glyph-on-opaque-backdrop child (`prod.fur.edge` vs `bench.fur.base_edge`): old and fixed renders match, soft overhang restored on every edge.

### 11.4 Harness additions

- `BENCH_WINDOW=800x1042` (env var, handled in the macOS Runner): sets the window content size at launch — the default is 800×600, and macOS state restoration silently brings back whatever the last manual size was, which is exactly how a measurement session ends up at the wrong fill-rate. All §11 numbers used it. The runner now needs `-ApplePersistenceIgnoreState YES` semantics anyway; the Runner re-applies the size on the next runloop turn to beat restoration.
- `BENCH_SNAPSHOT=<id>[,<id>…]` + `BENCH_SNAPSHOT_T=2.0,7.3`: renders each config at fixed virtual times and writes PNGs via `RepaintBoundary.toImage` (no screen-recording permission needed; pixel-exact and reproducible). Files land in the sandboxed app container's tmp dir; paths are printed.
- New worst-case anchors `bench.fur.base_clicks5` and `bench.iwrap.base_rect` keep the pre-optimization shaders measurable under the same load as the hottest prod configs (and BENCH_COMPARE-able against them on a synced clock).
- New edge-exercising fur configs `prod.fur.edge` / `bench.fur.base_edge` (`benchGlyphOnBackdrop`: glyph on an opaque non-matching backdrop) — the only fur configs whose mask has real edges (see §11.3). Use these for any future change touching fur's mask/lean path.
- Caveat: `bench.fur.noedgelean` (old stub variant) now spams a Metal pipeline "division by zero" compile error before falling back — an artifact of its stubbed `edgeStrength = 0` being constant-folded into a division during Metal specialization. Harness-only; fix or delete the stub if it's needed again.
