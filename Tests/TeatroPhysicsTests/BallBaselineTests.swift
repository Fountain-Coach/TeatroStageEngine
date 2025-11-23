import XCTest
@testable import TeatroPhysics

final class BallBaselineTests: XCTestCase {
    func testBallDropRespectsFloorAndSettles() {
        let scene = TPBallScene()
        let radius = scene.radius
        let epsilonPos = 1e-3
        let epsilonVel = 0.05

        let dt = 1.0 / 60.0
        let totalTime = 8.0
        let steps = Int(totalTime / dt)

        var lastSnapshot = scene.snapshot()

        for _ in 0..<steps {
            scene.step(dt: dt)
            lastSnapshot = scene.snapshot()

            // Floor non-penetration: centre must remain >= radius - epsilon
            XCTAssertGreaterThanOrEqual(
                lastSnapshot.position.y,
                radius - epsilonPos,
                "Ball should not penetrate below the floor"
            )

            // Room bounds in X/Z (keep a small margin inside the canonical room)
            XCTAssertLessThanOrEqual(abs(lastSnapshot.position.x), 15 - radius + epsilonPos)
            XCTAssertLessThanOrEqual(abs(lastSnapshot.position.z), 10 - radius + epsilonPos)
        }

        // After enough time, the ball should be near rest on the floor.
        let finalPos = lastSnapshot.position
        let finalVel = lastSnapshot.velocity
        XCTAssertLessThanOrEqual(abs(finalPos.y - radius), epsilonPos, "Ball should settle on the floor")
        XCTAssertLessThanOrEqual(length(finalVel), epsilonVel, "Ball velocity should decay under damping")
    }

    func testThrownBallMovesAcrossFloorAndSettles() {
        // Start the ball resting on the floor, then give it a horizontal speed.
        let radius = 1.0
        let scene = TPBallScene(
            initialPosition: TPVec3(x: 0, y: radius, z: 0),
            radius: radius,
            mass: 1.0
        )
        let epsilonPos = 1e-3
        let epsilonVel = 0.05

        scene.setHorizontalSpeed(4.0)
        let initialSnapshot = scene.snapshot()
        let initialX = initialSnapshot.position.x

        let dt = 1.0 / 60.0
        let totalTime = 10.0
        let steps = Int(totalTime / dt)

        var lastSnapshot = initialSnapshot
        var maxTravel: Double = 0

        for _ in 0..<steps {
            scene.step(dt: dt)
            lastSnapshot = scene.snapshot()

            // The ball should never tunnel through the floor.
            XCTAssertGreaterThanOrEqual(
                lastSnapshot.position.y,
                radius - epsilonPos,
                "Ball should not penetrate below the floor when thrown"
            )

            // Track horizontal travel distance.
            let travel = abs(lastSnapshot.position.x - initialX)
            if travel > maxTravel {
                maxTravel = travel
            }
        }

        // It should have moved a meaningful distance along X (at least two radii).
        XCTAssertGreaterThanOrEqual(
            maxTravel,
            2.0 * radius - epsilonPos,
            "Thrown ball should travel at least two radii across the floor"
        )

        // And it should eventually settle again near rest on the floor.
        let finalPos = lastSnapshot.position
        let finalVel = lastSnapshot.velocity
        XCTAssertLessThanOrEqual(abs(finalPos.y - radius), epsilonPos, "Thrown ball should end up on the floor")
        XCTAssertLessThanOrEqual(length(finalVel), epsilonVel, "Thrown ball velocity should decay under damping")
    }

    // Small helper to avoid repeating the length calculation.
    private func length(_ v: TPVec3) -> Double {
        v.length()
    }
}

