The Teatro puppet rig is a small tree of rigid bodies connected by distance constraints. Bodies:

- `bar` — the overhead crossbar.
- `torso` — main body segment.
- `head` — head block above torso.
- `handL`, `handR` — left and right hands/forearms.
- `footL`, `footR` — left and right feet/legs.

Skeleton constraints:
- `torso ↔ head` — keeps head above torso.
- `torso ↔ handL`, `torso ↔ handR` — keep hands attached near shoulders.
- `torso ↔ footL`, `torso ↔ footR` — keep feet attached near hips.

String constraints:
- `bar ↔ head` — central string from bar to head.
- `bar ↔ handL`, `bar ↔ handR` — strings from bar ends to hands.

All constraints are distance constraints with rest lengths derived from initial positions. Visual “strings” in renderers should be drawn between the corresponding body centers or anchor points, using the current positions from the physics snapshot.

