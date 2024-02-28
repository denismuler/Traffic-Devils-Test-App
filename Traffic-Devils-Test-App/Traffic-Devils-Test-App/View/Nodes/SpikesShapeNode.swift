//
//  SpikesShapeNode.swift
//  Traffic-Devils-Test-App
//
//  Created by Georgie Muler on 28.02.2024.
//

import Foundation
import SpriteKit

class WhiteStarShapeNode: SKShapeNode {

    init(size: CGFloat, spikes: Int) {
        super.init()
        self.path = createStarPath(size: size, spikes: spikes)
        self.physicsBody = createPhysicsBody()
        self.fillColor = SKColor.white
        self.strokeColor = SKColor.white
        self.lineWidth = 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createStarPath(size: CGFloat, spikes: Int) -> CGPath {
        let path = CGMutablePath()

        let angleIncrement = CGFloat(2 * Double.pi / Double(spikes * 2))

        for i in 0..<(spikes * 2) {
            let radius = i % 2 == 0 ? size / 2 : size / 4
            let angle = CGFloat(i) * angleIncrement - CGFloat.pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    private func createPhysicsBody() -> SKPhysicsBody {
        let body = SKPhysicsBody(polygonFrom: self.path!)
        body.collisionBitMask = 0
        body.affectedByGravity = false
        return body
    }
}
