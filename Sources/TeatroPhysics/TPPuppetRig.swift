import Foundation

public struct TPPuppetSnapshot: Sendable, Equatable {
    public var bar: TPVec3
    public var torso: TPVec3
    public var head: TPVec3
    public var handL: TPVec3
    public var handR: TPVec3
    public var footL: TPVec3
    public var footR: TPVec3
}

public final class TPPuppetRig: @unchecked Sendable {
    public let world: TPWorld
    public let barBody: TPBody
    public let torsoBody: TPBody
    public let headBody: TPBody
    public let handLBody: TPBody
    public let handRBody: TPBody
    public let footLBody: TPBody
    public let footRBody: TPBody

    public init() {
        world = TPWorld()
        world.gravity = TPVec3(x: 0, y: -9.82, z: 0)
        world.linearDamping = 0.02

        barBody = TPBody(position: TPVec3(x: 0, y: 15, z: 0), mass: 0.1)
        torsoBody = TPBody(position: TPVec3(x: 0, y: 8, z: 0), mass: 1.0)
        headBody = TPBody(position: TPVec3(x: 0, y: 10, z: 0), mass: 0.5)
        handLBody = TPBody(position: TPVec3(x: -1.8, y: 8, z: 0), mass: 0.3)
        handRBody = TPBody(position: TPVec3(x: 1.8, y: 8, z: 0), mass: 0.3)
        footLBody = TPBody(position: TPVec3(x: -0.6, y: 5, z: 0), mass: 0.4)
        footRBody = TPBody(position: TPVec3(x: 0.6, y: 5, z: 0), mass: 0.4)

        world.addBody(barBody)
        world.addBody(torsoBody)
        world.addBody(headBody)
        world.addBody(handLBody)
        world.addBody(handRBody)
        world.addBody(footLBody)
        world.addBody(footRBody)

        func addDistance(_ a: TPBody, _ b: TPBody, stiffness: Double = 0.9) {
            let delta = b.position - a.position
            let rest = delta.length()
            world.addConstraint(TPDistanceConstraint(bodyA: a, bodyB: b, restLength: rest, stiffness: stiffness))
        }

        // Torso ↔ head / hands / feet (skeleton)
        addDistance(torsoBody, headBody, stiffness: 0.8)
        addDistance(torsoBody, handLBody, stiffness: 0.8)
        addDistance(torsoBody, handRBody, stiffness: 0.8)
        addDistance(torsoBody, footLBody, stiffness: 0.8)
        addDistance(torsoBody, footRBody, stiffness: 0.8)

        // Strings: bar ↔ head / hands
        addDistance(barBody, headBody, stiffness: 0.9)
        addDistance(barBody, handLBody, stiffness: 0.9)
        addDistance(barBody, handRBody, stiffness: 0.9)
    }

    public func step(dt: Double, time: Double) {
        driveBar(time: time)
        world.step(dt: dt)
    }

    public func snapshot() -> TPPuppetSnapshot {
        TPPuppetSnapshot(
            bar: barBody.position,
            torso: torsoBody.position,
            head: headBody.position,
            handL: handLBody.position,
            handR: handRBody.position,
            footL: footLBody.position,
            footR: footRBody.position
        )
    }

    private func driveBar(time: Double) {
        let sway = sin(time * 0.7) * 2.0
        let upDown = sin(time * 0.9) * 0.5
        barBody.position.x = sway
        barBody.position.y = 15 + upDown
        // keep bar roughly centered in z
        barBody.position.z = 0
    }
}

