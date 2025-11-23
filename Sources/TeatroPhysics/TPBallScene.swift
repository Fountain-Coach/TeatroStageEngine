import Foundation

public struct TPBallSnapshot: Sendable, Equatable {
    public var time: Double
    public var position: TPVec3
    public var velocity: TPVec3

    public init(time: Double, position: TPVec3, velocity: TPVec3) {
        self.time = time
        self.position = position
        self.velocity = velocity
    }
}

/// Minimal helper scene for the single-ball baseline described in
/// `spec/physics/ball-baseline.md`. This type is intentionally small and does
/// not introduce any new physics behaviour; it wires a TPWorld with a single
/// dynamic body and a ground constraint at y = 0 so tests can exercise the
/// world without pulling in the puppet rig.
public final class TPBallScene: @unchecked Sendable {
    public let world: TPWorld
    public let ballBody: TPBody
    private var time: Double = 0

    public let radius: Double

    /// Create a ball scene with the given initial position, radius, and mass.
    /// Defaults match the baseline spec: radius 1, mass 1, position (0, 12, 0).
    public init(
        initialPosition: TPVec3 = TPVec3(x: 0, y: 12, z: 0),
        radius: Double = 1.0,
        mass: Double = 1.0
    ) {
        self.radius = radius
        world = TPWorld()
        world.gravity = TPVec3(x: 0, y: -9.82, z: 0)
        world.linearDamping = 0.02

        // Treat the ball as a box collider with uniform half-extents; for the
        // purposes of the baseline invariants we only care about its overall
        // size, not its exact shape.
        let halfExtents = TPVec3(x: radius, y: radius, z: radius)
        ballBody = TPBody(position: initialPosition, mass: mass, halfExtents: halfExtents)
        world.addBody(ballBody)

        // Floor at y = 0, matching the stage room definition, with a bouncy
        // contact so the ball can rebound before settling.
        let ground = TPBouncyGroundConstraint(body: ballBody, floorY: 0, restitution: 0.4)
        world.addConstraint(ground)
    }

    public func step(dt: Double) {
        guard dt > 0 else { return }
        time += dt
        world.step(dt: dt)
    }

    public func snapshot() -> TPBallSnapshot {
        TPBallSnapshot(time: time, position: ballBody.position, velocity: ballBody.velocity)
    }

    /// Convenience for the thrown-ball scenario: set an initial horizontal
    /// velocity for the ball. This does not modify the world's gravity or
    /// damping; callers are responsible for starting from a suitable pose.
    public func setHorizontalSpeed(_ speed: Double) {
        ballBody.velocity = TPVec3(x: speed, y: 0, z: 0)
    }
}
