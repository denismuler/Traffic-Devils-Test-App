//
//  GameScene.swift
//  Traffic-Devils-Test-App
//
//  Created by Georgie Muler on 26.02.2024.
//

import UIKit
import SpriteKit
import CoreMotion
import WebKit


protocol GameSceneDelegate: AnyObject {
    func showWBView(win: Bool)
}

class GameScene: SKScene {
    
    private var motionManager = CMMotionManager()
    private var gameTimer: Timer?
    private var gameSpentTime: Int = 0
    private var timer: Timer?
    private var firstStrip: Bool = true
    private var gameIsStarted: Bool = false
    
    private var webView: WKWebView?
    
    private let ballCategory: UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    private let wallCategory: UInt32 = 0x1 << 2
    private let ballFallSpeed: CGFloat = 1000.0
    
    private var holeWidth: CGFloat = 50
    private var starSize: CGFloat = 40
    
    private var touchedNode: SKNode?
    weak var gameDelegate: GameSceneDelegate?
    
    
    private var startButton: SKSpriteNode = {
        let node = SKSpriteNode()
        node.size = CGSize(width: 150, height: 50)
        node.name = "playButton"
        node.color = .blue
        
        let playText = SKLabelNode(text: "PLAY")
        playText.fontName = "Arial-BoldMT"
        playText.name = "playButtonText"
        playText.fontSize = 32
        playText.fontColor = .black
        playText.position = CGPoint(x: 0, y: 0)
        playText.horizontalAlignmentMode = .center
        playText.verticalAlignmentMode = .center
        node.addChild(playText)
        
        return node
    }()
    
    private var timeLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.fontSize = 40
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.fontColor = .blue
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
        return label
    }()
    
    private var ball: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 20)
        node.name = "ball"
        node.fillColor = .yellow
        node.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        node.physicsBody?.restitution = 0.0
        node.physicsBody?.linearDamping = 0.0
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = 0x1 << 0
        node.physicsBody?.contactTestBitMask = 0x1 << 1
        
        return node
    }()
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: -ballFallSpeed)
        startButton.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        createWalls()
        setupAccelerometer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = self.atPoint(location)
            if node.name == "playButton" || node.name == "playButtonText"{
                startButton.setScale(0.9)
                startButton.alpha = 0.8
                touchedNode = node
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = self.atPoint(location)
            if node.name == "playButton" || node.name == "playButtonText" {
                
                self.isPaused = false
                addChild(ball)
                createStars()
                startStripGeneratorTimer()
                startGameTimer()
                addChild(timeLabel)
                timeLabel.text = "0"
                startButton.removeFromParent()
            } else {
                startButton.setScale(1.0)
                startButton.alpha = 1.0
            }
        }
    }
    
    private func createWalls() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.restitution = 0.0
        physicsBody?.categoryBitMask = wallCategory
        physicsBody?.collisionBitMask = ballCategory
    }
    
    private func setupAccelerometer() {
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            if let acceleration = data?.acceleration {
                self?.updateBallVelocity(acceleration: acceleration)
            }
        }
    }
    
    private func updateBallVelocity(acceleration: CMAcceleration) {
        let sensitivity: CGFloat = 750.0
        ball.physicsBody?.velocity.dx = CGFloat(acceleration.x) * sensitivity
    }
    
    private func startStripGeneratorTimer() {
        generateStripWithHole()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(generateStripWithHole), userInfo: nil, repeats: true)
    }
    
    @objc private func generateStripWithHole() {
        guard self.isPaused == false else { return }
        var moveRight = true
        let stripHeight: CGFloat = 5.0
        let stripWidth: CGFloat = size.width
        let holePosition = CGFloat.random(in: holeWidth / 2...(stripWidth - holeWidth / 2))
        let wallMoveSpeedCoefficient: CGFloat = 1.0 / 25.0
        var starPosX: CGFloat = 0
        var stripsMovementTimer: Timer?
        
        let leftStrip = SKSpriteNode(color: .white, size: CGSize(width: holePosition - holeWidth / 2, height: stripHeight))
        leftStrip.name = "strip"
        leftStrip.position = CGPoint(x: leftStrip.size.width / 2, y: -stripHeight / 2)
        setupStrip(strip: leftStrip)
        addChild(leftStrip)
        
        let rightStrip = SKSpriteNode(color: .white, size: CGSize(width: stripWidth - (holePosition + holeWidth / 2), height: stripHeight))
        rightStrip.name = "strip"
        rightStrip.position = CGPoint(x: size.width - rightStrip.size.width / 2, y: -stripHeight / 2)
        setupStrip(strip: rightStrip)
        addChild(rightStrip)
        
        let starOnStrip = WhiteStarShapeNode(size: starSize, spikes: 8)
        starOnStrip.name = "starOnStrip"
        starOnStrip.zRotation = CGFloat.pi
        starOnStrip.physicsBody?.contactTestBitMask = self.ballCategory
        let starOnStripWidth = starOnStrip.frame.size.width
        if leftStrip.size.width >= starOnStripWidth && rightStrip.size.width >= starOnStripWidth {
            if Bool.random() == true {
                starPosX = CGFloat.random(in: starOnStripWidth / 2...(leftStrip.size.width - starOnStripWidth / 2))
            } else {
                starPosX = CGFloat.random(in: leftStrip.size.width + holeWidth + starOnStripWidth / 2...stripWidth - starOnStripWidth / 2)
            }
        } else if leftStrip.size.width >= starOnStripWidth {
            starPosX = CGFloat.random(in: starOnStripWidth / 2...(leftStrip.size.width - starOnStripWidth / 2))
        } else if rightStrip.size.width >= starOnStripWidth {
            starPosX = CGFloat.random(in: leftStrip.size.width + holeWidth + starOnStripWidth / 2...stripWidth - starOnStripWidth / 2)
        }
        starOnStrip.position = CGPoint(x: starPosX, y: starOnStrip.frame.size.height / 2)
        if firstStrip == false {
            addChild(starOnStrip)
        }
        
        let leftStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        let removeAction = SKAction.removeFromParent()
        leftStrip.run(SKAction.sequence([leftStripMoveUpAction, removeAction]))
        
        let rightStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        rightStrip.run(SKAction.sequence([rightStripMoveUpAction, removeAction]))
        
        let starOnStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        starOnStrip.run(SKAction.sequence([starOnStripMoveUpAction, removeAction]))
        
        stripsMovementTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.01), repeats: true) { timer in
            guard self.isPaused == false else { return }
            if moveRight == true {
                leftStrip.size.width += 1
                rightStrip.size.width -= 1
                
                leftStrip.position.x = leftStrip.size.width / 2
                rightStrip.position.x = self.size.width - rightStrip.size.width / 2
                starOnStrip.position.x += 1
                
                setupStrip(strip: leftStrip)
                setupStrip(strip: rightStrip)
                
                if rightStrip.size.width <= self.ball.frame.width {
                    moveRight = false
                }
            } else {
                leftStrip.size.width -= 1
                rightStrip.size.width += 1
                
                leftStrip.position.x = leftStrip.size.width / 2
                rightStrip.position.x = self.size.width - rightStrip.size.width / 2
                starOnStrip.position.x -= 1
                
                setupStrip(strip: leftStrip)
                setupStrip(strip: rightStrip)
                
                if leftStrip.size.width <= self.ball.frame.width {
                    moveRight = true
                }
            }
        }
        if starOnStrip.position.y >= Double((self.view?.frame.size.height ?? 0) - (self.view?.safeAreaInsets.top ?? 0)) {
            starOnStrip.removeFromParent()
        }
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)), repeats: false) { timer in
            stripsMovementTimer?.invalidate()
            stripsMovementTimer = nil
        }
        
        firstStrip = false
        
        func setupStrip(strip: SKSpriteNode) {
            strip.physicsBody = SKPhysicsBody(rectangleOf: strip.size)
            strip.physicsBody?.categoryBitMask = self.obstacleCategory
            strip.physicsBody?.contactTestBitMask = self.ballCategory
            strip.physicsBody?.collisionBitMask = 0
            strip.physicsBody?.affectedByGravity = false
            strip.physicsBody?.allowsRotation = false
        }
        
    }
    
    private func createStars() {
        let screenWidth = size.width
        let screenHeight = size.height
        
        let numberOfstars = Int(screenWidth / starSize)
        
        let distanceBetweenstars = screenWidth / CGFloat(numberOfstars)
        
        for i in 0..<numberOfstars {
            let star = WhiteStarShapeNode(size: starSize, spikes: 10)
            star.name = "star"
            
            let xPosition = CGFloat(i) * distanceBetweenstars + distanceBetweenstars / 2
            let yPosition = screenHeight - star.frame.size.height / 2 - (view?.safeAreaInsets.top ?? 0)
            
            star.position = CGPoint(x: xPosition, y: yPosition)
            
            addChild(star)
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.gameSpentTime += 1
            self.timeLabel.text = "\(self.gameSpentTime)"
            print("Gametimer", self.gameSpentTime)
            if self.gameSpentTime >= 30 {
                self.gameIsWon()
            }
        }
    }
    
    private func endGame() {
        removeAllChildren()
        removeAllActions()
        self.isPaused = true
        timer?.invalidate()
        timer = nil
        gameTimer?.invalidate()
        gameTimer = nil
        gameIsStarted = false

        gameDelegate?.showWBView(win: false)
        gameSpentTime = 0
    }
    
    private func gameIsWon() {
        removeAllChildren()
        removeAllActions()
        self.isPaused = true
        timer?.invalidate()
        timer = nil
        gameTimer?.invalidate()
        gameTimer = nil
        gameIsStarted = false

        gameDelegate?.showWBView(win: true)
        gameSpentTime = 0
    }
    
    func startGame() {
        guard gameIsStarted == false else {
            self.isPaused = false
            return }
        firstStrip = true
        self.isPaused = true
        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
        self.startButton.alpha = 1.0
        self.startButton.xScale = 1.0
        self.startButton.yScale = 1.0
        addChild(startButton)
        gameIsStarted = true
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.node?.name == "strip") && contact.bodyB.node?.name == "star" {
            contact.bodyA.node?.removeFromParent()
        } else if contact.bodyB.node?.name == "strip" && contact.bodyA.node?.name == "star" {
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyA.node?.name == "ball" && (contact.bodyB.node?.name == "star" || contact.bodyB.node?.name == "starOnStrip") {
            endGame()
        } else if contact.bodyB.node?.name == "ball" && (contact.bodyA.node?.name == "star" || contact.bodyA.node?.name == "starOnStrip") {
            endGame()
        }
        
        if contact.bodyA.node?.name == "star" && contact.bodyB.node?.name == "starOnStrip" {
            contact.bodyB.node?.removeFromParent()
            
        } else if contact.bodyB.node?.name == "star" && contact.bodyA.node?.name == "starOnStrip" {
            contact.bodyA.node?.removeFromParent()
        }
    }
}

