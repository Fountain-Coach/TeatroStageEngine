TeatroPhysics is a small, deterministic game engine for the Teatro puppet stage. It is written in pure Swift, has no UI or rendering dependencies, and is designed to be embedded into hosts like FountainKit, MetalViewKit demos, or command‑line tools. This document describes the engine as a product, not just as a math helper.

## 0. Purpose and Scope

TeatroPhysics exists to make one specific class of scenes precise and repeatable: a Teatro stage with gravity, hanging puppets, strings, and a ground plane. The primary reference implementation is the JavaScript demo in `Design/teatro-engine-spec/demo1.html` (Three.js + Cannon.js). The Swift engine does not try to be a general physics playground; it aims to mirror that behaviour closely, then expose a clean API for other instruments that want the same rig logic.

The engine stays headless:
- It advances bodies in time under forces and constraints.
- It exposes snapshots (positions and velocities).
- It knows nothing about cameras, Metal, SDL, or Teatro prompts.

Hosts are responsible for:
- choosing a projection and camera,
- drawing bodies as geometry (boxes, lines, strings, lights),
- mapping engine state into Property Exchange or OpenAPI when needed.

## 1. World Model

The engine uses a simple, conventional world:
- Right‑handed coordinates, with `y` up.
- Positions and lengths in arbitrary units (the Three.js demo treats them as “meters”; we mirror its relative sizes).
- Time in seconds.

The world is represented by `TPWorld`:
- holds all `TPBody` instances (rigid bodies),
- holds all `TPConstraint` instances (joints, strings),
- has global parameters:
  - `gravity: TPVec3` (default `(0, -9.82, 0)`),
  - `linearDamping: Double` (simple velocity damping per step).

Integration is semi‑implicit Euler:
1. For each body with non‑zero `mass`, we compute acceleration from gravity.
2. We integrate `velocity` from acceleration and damping.
3. We integrate `position` from velocity and timestep.
4. We then run all constraints once to correct positions.

Callers own the clock. A host creates a world, then repeatedly calls `world.step(dt:)` with its chosen `dt` (the puppet demos assume `dt ≈ 1/60`).

## 2. Bodies

`TPBody` is the engine’s rigid body:
- `position: TPVec3` — center of mass in world space.
- `velocity: TPVec3` — linear velocity.
- `mass: Double` and derived `invMass`.

Bodies do not yet rotate. The puppet is modelled as a set of point‑masses connected by distance constraints; volumes (boxes) are reintroduced by the renderer, not by the solver. This keeps the engine small and predictable while still allowing a marionette‑style rig.

Typical usage:
- A bar, torso, head, hands, and feet are all separate bodies.
- A “ground” is implicit (the renderer and/or higher‑level engine may add contacts later).

## 3. Constraints

The constraint system is intentionally small:

- `TPConstraint` is a protocol with a single method: `solve(dt:)`.
- `TPDistanceConstraint` keeps two bodies at approximately a target distance:
  - constructed with `bodyA`, `bodyB`, `restLength`, and `stiffness`,
  - on each `solve` it computes the error between current distance and `restLength`,
  - then nudges `position` of both bodies along the line between them, scaled by `stiffness` and mass.

This behaves like a soft rope or rod:
- high stiffness ≈ tight string,
- lower stiffness ≈ rubbery connection.

Additional constraints can be added later (hinges, point‑to‑point joints that respect offsets) using the same interface. For the first Teatro puppet, distance constraints are enough to reproduce the visual behaviour.

## 4. Puppet Rig Specification

The Fadenpuppe is represented by `TPPuppetRig`. It owns a `TPWorld` plus the specific bodies and constraints that mirror the Three.js demo:

Bodies (all `TPBody`):
- `barBody` — overhead crossbar; light mass, slightly above the puppet.
- `torsoBody` — central body segment.
- `headBody` — head block; above torso.
- `handLBody`, `handRBody` — left and right hands/forearms.
- `footLBody`, `footRBody` — left and right feet/legs.

Initial positions are chosen to match the JS demo descriptively:
- Bar around `(0, 15, 0)`.
- Torso around `(0, 8, 0)`.
- Head around `(0, 10, 0)`.
- Hands around `(-1.8, 8, 0)` and `(1.8, 8, 0)`.
- Feet around `(-0.6, 5, 0)` and `(0.6, 5, 0)`.

Constraints:
- Skeleton:
  - torso ↔ head,
  - torso ↔ each hand,
  - torso ↔ each foot.
- Strings:
  - bar ↔ head,
  - bar ↔ each hand.

Each constraint measures the initial distance on construction and keeps that as `restLength`. Stiffness is tuned to give the same “loose but controlled” motion as the Three.js rig: the bar moves first, then the limbs swing and settle.

The rig exposes:
- `step(dt:time:)` — advances the world by one timestep; it also calls a private `driveBar(time:)` that moves the crossbar in a side‑to‑side + up/down pattern matching the JS demo.
- `snapshot()` — returns `TPPuppetSnapshot` with the current positions of all bodies.

Hosts can convert snapshots into their own vector types (for example, `TeatroVec3` in MetalViewKit) and draw the puppet however they like: as boxes, lines, or silhouettes.

## 5. Stage and Room

TeatroPhysics itself does not draw or even explicitly represent the room geometry; it assumes:
- a ground plane at `y = 0` (the puppet’s feet are near this plane),
- walls and doors are a responsibility of the renderer,
- all bodies are simulated in the same world coordinates as in the reference demo.

The canonical room for the puppet demo is:
- floor: rectangle `30 × 20` units centered at the origin,
- walls: three sides of that floor raised to height `20` units,
- door: a small rectangle cut into the right wall (approx. 8 units high).

MetalViewKit and other renderers should use the same numeric values when projecting this world into view space so that camera and rig feel identical to the reference.

## 6. Embedding API

The engine is designed to be easy to embed:

1. A host adds the `TeatroPhysics` SwiftPM package:
   - for in‑repo use (as in FountainKit): `.package(url: "https://github.com/Fountain-Coach/TeatroPhysics.git", from: "0.2.0")`.
2. It imports `TeatroPhysics` and chooses one of two paths:
   - Use `TPWorld` directly for a custom scene:
     - create bodies, add them to the world,
     - add constraints,
     - call `world.step(dt:)`,
     - read `body.position` values.
   - Use `TPPuppetRig` for the canonical Fadenpuppe:
     - create a rig instance,
     - repeatedly call `rig.step(dt: time:)` from a render loop,
     - call `rig.snapshot()` and feed positions into a renderer.
3. All time‑stepping happens on the host’s schedule; there are no timers inside the engine.

The engine is sendable and pure Swift; no AppKit, UIKit, Metal, or SwiftUI are imported in this package. That makes it suitable for macOS apps, command‑line tools, or tests.

## 7. Determinism and Testing

TeatroPhysics aims to be deterministic for a given sequence of `step(dt:)` calls:
- There is no hidden randomisation.
- Gravity and damping are explicit.
- Constraints are applied in a stable order within a single world instance.

The test suite (under `Tests/TeatroPhysicsTests`) covers:
- free‑fall sanity (`testFreeFallMovesDownwards`),
- distance constraint behaviour over multiple steps (`testDistanceConstraintKeepsBodiesClose`).

As the engine evolves, additional tests should lock in puppet rig behaviour at a coarse level, for example:
- positions staying within a bounding box,
- average energy not exploding over a long simulation,
- string distances staying near their rest length.

## 8. Future Extensions

The short‑term evolution path is clear:
- add more constraint types (e.g. a point‑to‑point joint that respects anchor offsets),
- add basic ground contacts for reps or props,
- expose hooks so other Teatro instruments (constellation fields, doors, backlines) can attach their own bodies and constraints into the same world.

The guiding rule, though, is to keep TeatroPhysics focused: a small, predictable engine for Teatro rigs, not a general‑purpose game engine. When in doubt, prefer a narrow, well‑documented feature that matches a real Teatro demo over a generic but unused abstraction.

