This directory defines how the Teatro Stage Engine exposes its state to other systems: snapshots, logs, and potential network APIs. The goal is that a host like FountainKit can record and replay a session, or drive a renderer in another language, without guessing field names.

Files:
- `snapshot-schema.md` — the logical structure of a frame.
- `integration-notes.md` — how this maps into OpenAPI/PE or other host‑level abstractions.

For how these interchange rules fit into the broader “Teatro Stage as instruments” story in FountainKit (world/puppet/camera/recording surfaces), see `docs/TeatroStage-Instruments-Map.md`.
