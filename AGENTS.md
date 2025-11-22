TeatroPhysics now acts as the core of a broader Teatro Stage Engine: the rigid‑body solver and puppet rig live here, alongside the written specs for camera, room, style, input, and interchange. The Swift code remains pure and renderer‑agnostic; the surrounding `spec/` tree is the human‑readable contract that other repos (FountainKit, JS demos, tools) must follow.

Operating rules:
- This repository is the authoritative description of the Teatro puppet stage as an engine. The Three.js demo is a historical reference; if behaviour diverges, update the spec here first, then align implementations.
- Physics stays deterministic, headless, and testable — no Metal, SDL, or UI dependencies. Renderers treat this package as a model/solver and map its snapshots into their own coordinate systems and visuals.
- Specs live under `spec/` in small, focused directories (`camera`, `physics`, `rig-puppet`, `stage-room`, `style`, `interchange`). Each directory has its own `AGENTS.md` describing what belongs there and must be kept current when code or demos change.

Implementation norms:
- Prefer small, immutable value types (`TPVec3`) and thin reference types (`TPBody`, rigs) only where identity is required.
- Keep the integrator simple (semi‑implicit Euler) and stable at 60 Hz; document assumptions about timestep in `spec/physics/world-and-timestep.md`.
- Constraint types are explicit (`TPDistanceConstraint` for now); new constraints must be justified by a real Teatro use‑case and documented before being added.
- Tests should lock in puppet behaviour at a coarse level (energy not exploding, distances staying near targets, rig remaining within bounds) rather than only checking single‑step math.

