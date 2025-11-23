Teatro Stage as Instruments — Engine View
=========================================

This note explains how the Teatro Stage Engine (this package) relates to instruments and tools in FountainKit. The core idea is to keep TeatroStageEngine focused on **physics and specs**, while FountainKit owns **instrument surfaces** (OpenAPI, PE facts, Teatro prompts). Hosts such as MetalViewKit demos, web apps, or MIDI tools sit on top of both.

This document mirrors the conceptual map in the FountainKit repo (`Design/TeatroStage-Instruments-Map.md`), but from the engine’s point of view.

1. Layers and Responsibilities
------------------------------

From this package’s perspective, there are three layers:

- **Engine layer (this repo)**  
  - Owns: world/rig geometry, gravity and damping, constraint behaviour, time stepping, and snapshot formats.  
  - Implementation: `Sources/TeatroPhysics/*` and specs under `spec/**`.  
  - Guarantees: deterministic state evolution given initial conditions and inputs; stable snapshot schema.

- **Instrument layer (FountainKit)**  
  - Owns: which parts of the stage are controllable or observable as tools, how they are named, and how they are exposed via OpenAPI and PE facts.  
  - Implementation: curated OpenAPI specs under `Packages/FountainSpecCuration/openapi/**` in FountainKit, plus facts in FountainStore and Teatro prompts.  
  - From this repo’s view: the instrument layer is a client; it must treat `spec/**` and the Swift types here as the authority.

- **Host layer (apps / frontends)**  
  - Owns: rendering, input, session management.  
  - Examples:
    - MetalViewKit host in FountainKit (`teatro-stage-app`),
    - Teatro Stage web demo (Three.js + Cannon‑ES),
    - future MIDI/LLM hosts that talk to FountainKit instruments.  
  - These hosts call into the engine or instrument surfaces; they do not change physics directly.

2. Engine Domain (What Exists on the Stage)
-------------------------------------------

TeatroStageEngine defines the **stage domain**; instruments should always be thin veneers over these concepts:

- **World**  
  - Right‑handed 3D world, `y` up, with abstract units aligned with the Three.js demo scale.  
  - Implemented by `TPWorld`, `TPBody`, and `TPConstraint` in `Sources/TeatroPhysics`.  
  - Rules (gravity, damping, timestep, constraint behaviour) are described in `spec/physics/**`.

- **Puppet rig**  
  - Fadenpuppe rig with bodies (`bar`, `torso`, `head`, `handL/R`, `footL/R`) connected by distance constraints (bones + strings).  
  - Topology and geometry in `spec/rig-puppet/**`; implementation in `TPPuppetRig`.  
  - Public contract: `step(dt:time:)` and `snapshot()` for hosts.

- **Stage room**  
  - Three‑sided room with floor, walls, and a door, specified in `spec/stage-room/**`.  
  - Used by renderers to draw the same physical space everywhere.

- **Camera and style**  
  - Orthographic camera model with fixed elevation, orbit azimuth, and clamped zoom, defined in `spec/camera/**`.  
  - Paper‑stage visual style (palette, line weights, lights) defined in `spec/style/**`.  
  - Implementations (Metal, web) follow these docs; the engine remains renderer‑agnostic.

- **Snapshots and interchange**  
  - Snapshot schema (`time`, `camera`, `bodies` with positions/velocities) in `spec/interchange/snapshot-schema.md`.  
  - Integration notes for hosts (OpenAPI/PE, file formats) in `spec/interchange/integration-notes.md`.

Any change to these concepts starts by updating the relevant `spec/**` document, then the Swift implementation, then hosts.

3. Expected Instrument Set in FountainKit
-----------------------------------------

FountainKit instruments are **not** defined in this repo, but they are expected to slice the stage domain into a few small surfaces. From TeatroStageEngine’s point of view, hosts will typically create instruments along these lines:

- **Stage World instrument**  
  - Controls: global physics knobs (gravity, damping, reset/seed, run/pause).  
  - Reads: derived health signals (e.g. average energy, bounds violations).  
  - Backed by: `TPWorld` state and physics specs in `spec/physics/**`.

- **Puppet instrument**  
  - Controls: rig‑level inputs (bar motion profile, scripted gestures/poses).  
  - Reads: puppet pose (positions of torso/head/hands/feet) and simple stability/frame checks.  
  - Backed by: `TPPuppetRig` and rig specs in `spec/rig-puppet/**`.

- **Camera instrument**  
  - Controls: camera azimuth, zoom, framing presets within spec‑defined bounds.  
  - Reads: current camera state and invariants (e.g. puppet head stays visible).  
  - Backed by: camera model in `spec/camera/**`, plus host‑specific camera abstractions.

- **Style / lighting instrument (optional)**  
  - Controls: constrained palette/lighting presets and small numeric tweaks (intensity, radius).  
  - Reads: current style and light configuration.  
  - Backed by: style specs in `spec/style/**` and renderer parameters in hosts.

- **Recording / playback instrument (optional)**  
  - Controls: snapshot recording, named takes, playback cursors and scrubbing.  
  - Reads: current playback time, take metadata.  
  - Backed by: snapshot schema and integration rules in `spec/interchange/**`.

These instruments should never re‑define physics or geometry; they only expose existing engine parameters and snapshots in a spec‑first way.

4. Mapping Rules for Hosts and Instruments
------------------------------------------

When a host (FountainKit or otherwise) uses this engine as a set of instruments, it should follow a few rules:

- **Specs + engine are authoritative**  
  - Geometry, physics parameters, camera maths, and style bounds must come from `spec/**` and `Sources/TeatroPhysics`, not from ad‑hoc constants in the host.

- **Specs → OpenAPI → facts**  
  - If you expose stage capabilities via HTTP or PE, define dedicated OpenAPI specs (e.g. `teatro-stage-world`, `teatro-stage-puppet`, `teatro-stage-camera`) that mirror the snapshot and physics rules here.  
  - Generate PE facts from those specs (in FountainKit, this is done via `openapi-to-facts` / Tools Factory) instead of hand‑writing mappings.

- **Deterministic behaviour and tests**  
  - Given the same initial conditions, timestep schedule, and instrument commands, the engine should evolve deterministically.  
  - Hosts are encouraged to add tests or robot scripts that call into instruments, record snapshots, and assert invariants over time (e.g. “no body leaves the room”; “default camera keeps the puppet in frame”).

- **Snapshots as the bridge**  
  - Use the snapshot schema in `spec/interchange/snapshot-schema.md` for logs, replay files, and HTTP responses.  
  - Avoid inventing host‑specific frame formats that diverge from this schema.

- **Prompts live elsewhere**  
  - Teatro prompts and facts do **not** live in this repo. In FountainKit, they are generated by the Teatro Prompt Factory and stored in FountainStore.  
  - When documenting instruments, point back to this repository as the source of truth for engine behaviour.

5. Where to Look Next
----------------------

From this repo, the key entry points for instrument authors are:

- Engine core: `Sources/TeatroPhysics/*`  
  (`TPWorld`, `TPBody`, `TPConstraint`, `TPPuppetRig`).
- Specs:
  - Physics: `spec/physics/**`
  - Rig: `spec/rig-puppet/**`
  - Room: `spec/stage-room/**`
  - Camera: `spec/camera/**`
  - Style: `spec/style/**`
  - Interchange: `spec/interchange/**`
  - Authoring UX: `spec/authoring/**`

For the FountainKit‑side view (how these concepts become concrete instruments, OpenAPI specs, and facts), see the `Design/TeatroStage-Instruments-Map.md` document in the FountainKit repository.

