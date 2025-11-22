Constraint model:
- All constraints conform to `TPConstraint` and implement `solve(dt:)`.
- Constraints operate in world space and may directly adjust body positions to reduce error; velocity is indirectly affected because the next integration step will react to position changes.

`TPDistanceConstraint`:
- Fields:
  - `bodyA`, `bodyB`: the two bodies being constrained.
  - `restLength`: desired distance between their positions.
  - `stiffness`: scalar in `(0, 1]` controlling how aggressively the constraint corrects error.
- Behaviour:
  - Let `delta = bodyB.position − bodyA.position`, `dist = |delta|`.
  - If `dist` is near zero, do nothing.
  - Compute `diff = (dist − restLength) / dist`.
  - Compute correction vector `impulse = delta * (0.5 * stiffness * diff)`.
  - Move bodies:
    - if `bodyA.invMass > 0`, `bodyA.position += impulse`,
    - if `bodyB.invMass > 0`, `bodyB.position -= impulse`.
- This keeps the distance between bodies close to `restLength` without being perfectly rigid; the exact tolerance depends on `stiffness`, `dt`, and damping.

Future constraints:
- Hinges, point‑to‑point joints with anchors, and simple ground contacts can be added, but each must be specified here before implementation.
- New constraints should remain small and focused, and should be motivated by a concrete Teatro rig requirement (e.g. door hinges, backline props).

