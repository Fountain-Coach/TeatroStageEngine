Ball Baseline — Single Rigid Body World Check
=============================================

This document defines a minimal, canonical physics scenario for the Teatro Stage Engine: a single rigid ball falling onto the stage floor inside the standard Teatro room. The goal is to provide a simple, repeatable baseline that validates the world model (gravity, damping, floor contact) before introducing puppets, strings, or other rigs.

Implementations in Swift (`TeatroPhysics`), Cannon‑ES, or other backends MUST be able to reproduce this scenario within the bounds described here. Tests in each host are expected to assert these invariants explicitly.

1. World setup
--------------

The ball baseline uses the same world model as the main stage:

- Coordinates: right‑handed, `x` right, `y` up, `z` forward, as in `world-and-timestep.md`.
- Gravity: `(0, -9.82, 0)`.
- Linear damping: `linearDamping = 0.02` (applied each step as in `world-and-timestep.md`).
- Floor: infinite or sufficiently large static collider aligned with the stage floor plane at `y = 0`.
- Room extents (for invariants):
  - `x ∈ [-15, 15]`,
  - `z ∈ [-10, 10]`,
  - `y ∈ [0, 20]`.

The timestep model is identical to the rest of the engine:

- Reference timestep: `dt_ref = 1/60` seconds.
- Hosts may pass variable `dt` but SHOULD clamp into `[1/120, 1/30]` for stability.

2. Ball parameters
------------------

The ball is a single dynamic rigid body with a sphere shape:

- Radius: `r = 1.0` world units.
- Mass: `m = 1.0` (kilogram‑like).
- Shape: sphere centred on the body position.

Initial pose at `t = 0`:

- Position: `p0 = (0, 12, 0)`.
- Linear velocity: `v0 = (0, 0, 0)`.
- Angular velocity: undefined / zero; orientation does not matter for this baseline.

This places the sphere well inside the room, above the floor, without touching the walls.

3. Simulation procedure
-----------------------

For the baseline scenario, hosts run the following procedure:

1. Construct a world with gravity, damping, and floor plane as described above.
2. Add a single dynamic rigid body representing the ball with the parameters from section 2.
3. Simulate for `T = 8` seconds using:
   - fixed steps of `dt = 1/60`, or
   - host‑appropriate `dt` values in `[1/120, 1/30]` such that the total simulated time is `T` (the exact number of steps may vary).
4. At each step, after integration and constraint resolution, record the ball position and velocity.

No other forces or bodies participate in this scenario.

4. Invariants (normative)
-------------------------

Implementations MUST satisfy the following invariants within reasonable numeric tolerances (`ε_pos` and `ε_vel` chosen by tests, e.g. `1e-3` to `1e-2`):

4.1 Floor non‑penetration

Let `y_c(t)` be the y‑coordinate of the ball’s centre at time `t`. Since the ball has radius `r` and the floor is at `y = 0`:

- For all steps `t` in `[0, T]`,  
  `y_c(t) ≥ r − ε_pos`.

This ensures the sphere never penetrates visually below the floor plane.

4.2 Room bounds

Let `(x_c(t), y_c(t), z_c(t))` be the ball centre at time `t`. For all steps `t` in `[0, T]`:

- `x_c(t) ∈ [-15 + r, 15 - r]` within `ε_pos`.
- `z_c(t) ∈ [-10 + r, 10 - r]` within `ε_pos`.

In this baseline scenario, with no lateral impulses, the ball is expected to remain near `x = 0, z = 0`, but the bounds above leave room for small numeric drift.

4.3 Settling under damping

Let `v(t)` be the ball’s linear velocity at time `t` and `‖v(t)‖` its magnitude. Under gravity and `linearDamping = 0.02`, the ball should bounce a few times and then settle onto the floor.

Define a “near rest” threshold `ε_vel` (e.g. `0.05` units/s). Then:

- There exists a time `t_rest ≤ T` such that for all subsequent steps `t ≥ t_rest`,  
  `‖v(t)‖ ≤ ε_vel` and `|y_c(t) − r| ≤ ε_pos`.

Tests MAY choose a more conservative `T` (e.g. 10 seconds) if required by the backend.

4.4 Symmetry (optional, recommended)

Since the baseline uses a symmetric initial pose with no lateral forces:

- For all steps `t` up to the first few bounces, `x_c(t)` SHOULD remain close to `0` (within a small band, e.g. `|x_c(t)| ≤ 0.1`).
- Any drift beyond that band SHOULD be attributable to known integrator or constraint differences and documented in tests.

5. Reference hosts and tests
----------------------------

Each implementation that embeds the Teatro Stage Engine is expected to carry a small test harness for this scenario:

- Swift (`TeatroPhysics`):
  - A `TPBallScene` helper that owns `TPWorld` + one `TPBody` sphere and exposes `step(dt:)` and `snapshot()`.
  - Tests that:
    - assert floor non‑penetration,
    - assert room bounds, and
    - confirm settling behaviour by checking velocity and height after `T` seconds.

- JavaScript / TypeScript (Cannon‑ES):
  - A `BallWorld` helper that mirrors the same parameters and API.
  - Vitest or similar tests asserting the same invariants on recorded snapshots.

Differences between backends (e.g. bounce count, exact decay curve) are acceptable as long as all normative invariants in section 4 are met.

6. Usage and evolution
----------------------

The ball baseline is intended as a “smoke test” for the physics world:

- Run this scenario first when changing integrator details, gravity, floor handling, or damping behaviour.
- Ensure both the Swift and JS/Cannon implementations continue to satisfy the invariants before moving on to more complex rigs (puppet, strings, controller).

If future changes require different parameters (for example, a different damping model), update this file alongside the corresponding tests and implementations, and document any relaxed or tightened bounds.

