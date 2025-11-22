The canonical Teatro room for the puppet stage is a simple three‑sided box:

- Floor: rectangle 30 × 20 units in the XZ plane, centered at the origin.
  - X ranges from −15 to +15.
  - Z ranges from −10 (back) to +10 (front).
  - The floor lies at `y = 0`.

- Back wall: rectangle 30 × 20 at Z = −10.
  - X ranges from −15 to +15.
  - Y ranges from 0 to 20.

- Left wall: rectangle 20 × 20 at X = −15.
  - Z ranges from −10 to +10.
  - Y ranges from 0 to 20.

- Right wall: rectangle 20 × 20 at X = +15.
  - Z ranges from −10 to +10.
  - Y ranges from 0 to 20.

Door (on right wall, Three.js reference):
- A smaller rectangle cut into the right wall, roughly 8 units high, positioned toward the back:
  - X fixed at +15.
  - Z from −4 to −1.
  - Y from 0 to 8.

The puppet rig origin is near the center of the floor at `(0, 0, 0)`. Renderers should draw edges for floor and walls using these coordinates to match the JS demo.

