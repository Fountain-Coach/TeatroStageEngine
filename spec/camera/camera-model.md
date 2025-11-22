The Teatro puppet stage uses a true orthographic camera with a fixed elevation and a configurable azimuth around the Y‑axis. The reference implementation in JavaScript uses:

- `frustumSize = 40`
- an `OrthographicCamera(left, right, top, bottom, near, far)` where:
  - `left = (frustumSize * aspect) / -2`
  - `right = (frustumSize * aspect) / 2`
  - `top = frustumSize / 2`
  - `bottom = -frustumSize / 2`
- a camera position at a fixed distance `distance = 60` from the origin:
  - azimuth `cameraAzimuth` (around Y),
  - elevation `cameraElevation = atan(1 / sqrt(2))` (~35.26°),
  - position:
    - `x = distance * cos(cameraAzimuth)`
    - `y = distance * sin(cameraElevation)`
    - `z = distance * sin(cameraAzimuth)`
- a `lookAt` target of `(0, 5, 0)` — slightly above the floor, near the puppet’s torso.

The Swift engine treats these constants as canonical:
- Implementations should use the same frustum formulas when projecting the stage to keep floor and wall proportions consistent across viewports.
- Camera elevation remains fixed; orbiting is done purely by changing azimuth.
- Zoom is modelled as a scalar on the orthographic bounds (and/or a separate orthographic zoom field), constrained to `[0.5, 3.0]` as in the JS demo.

Any change to these numbers must be justified (for example, to improve readability) and propagated to renderers that want visual parity.

