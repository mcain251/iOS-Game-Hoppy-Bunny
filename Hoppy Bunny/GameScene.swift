//
//  GameScene.swift
//  Hoppy Bunny
//
//  Created by Marshall Cain on 6/19/17.
//  Copyright © 2017 Marshall Cain. All rights reserved.
//

import SpriteKit

enum GameSceneState {
    case inactive, active, gameOver
}

var gameState: GameSceneState = .inactive

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero: SKSpriteNode!
    var sinceTouch: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 175
    var scrollLayer: SKNode!
    let scrollSpeed2: CGFloat = 25
    var scrollLayer2: SKNode!
    let scrollSpeed3: CGFloat = 50
    var scrollLayer3: SKNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    var buttonRestart: MSButtonNode!
    var buttonPlay: MSButtonNode!
    var pauseButton: MSButtonNode!
    var pauseButton2: SKNode!
    var pauseButton3: SKNode!
    var pauseLabel: SKLabelNode!
    var scoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    var points = 0
    var bumped = false
    var highScore = UserDefaults().integer(forKey: "HIGHSCORE")
    let jumpSound = SKAction.playSoundFileNamed("187025__lloydevans09__jump1", waitForCompletion: false)
    let goalSound = SKAction.playSoundFileNamed("187024__lloydevans09__jump2", waitForCompletion: false)
    let deathSound = SKAction.playSoundFileNamed("364929__josepharaoh99__game-die", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
    
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNode(withName: "//scrollLayer")
        
        /* Set reference to second scroll layer node */
        scrollLayer2 = self.childNode(withName: "//scrollLayer2")
        
        /* Set reference to third scroll layer node */
        scrollLayer3 = self.childNode(withName: "//scrollLayer3")
        
        /* Set reference to obstacle source node */
        obstacleSource = self.childNode(withName: "obstacle")
        
        /* Set reference to obstacle layer node */
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        /* Set reference to restart button */
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        /* Set reference to play button */
        buttonPlay = self.childNode(withName: "buttonPlay") as! MSButtonNode
        
        /* Set reference to the pause button */
        pauseButton = self.childNode(withName: "pauseButton") as! MSButtonNode
        pauseButton2 = self.childNode(withName: "pauseButton2")
        pauseButton3 = self.childNode(withName: "pauseButton3")
        pauseButton.state = .MSButtonNodeStateHidden
        pauseButton2.isHidden = true
        pauseButton3.isHidden = true
        
        /* Set reference to score label */
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        /* Set reference to high score label */
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        
        /* Set reference to pause label */
        pauseLabel = self.childNode(withName: "pauseLabel") as! SKLabelNode
        pauseLabel.text = ""
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
        /* Setup restart button selection handler */
        buttonRestart.selectedHandler = {
            
            /* Set the gameState to start the game */
            gameState = .active
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene?.scaleMode = .aspectFill
            
            /* Restart game scene */
            skView?.presentScene(scene)
        }
        
        /* Setup play button selection handler */
        buttonPlay.selectedHandler = {
            
            /* Set the gameState to start the game */
            gameState = .active
            
            /* Reveal the pause button */
            self.pauseButton.state = .MSButtonNodeStateActive
            self.pauseButton2.isHidden = false
            self.pauseButton3.isHidden = false
        }
        
        /* Setup pause button selection handlers */
        pauseButton.selectedHandler = {
            self.isPaused = !self.isPaused
            if self.isPaused {
                self.pauseLabel.text = "Paused"
            }
            else {
                self.pauseLabel.text = ""
            }
        }
        
        /* Hide restart button */
        buttonRestart.state = .MSButtonNodeStateHidden
        
        /* Reset score label */
        scoreLabel.text = "\(points)"
        
        /* Display highscore label */
        highScoreLabel.text = "High: \(highScore)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Ensure only called while game running */
        if gameState != .active { return }
        
        /* Reset velocity, helps improve response against cumulative falling velocity */
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        /* Apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(100)
        
        /* Reset touch timer */
        sinceTouch = 0
        
        /* Play sound effect */
        run(jumpSound)
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        /* Ensure only called while game running */
        if gameState == .active {
            
            /* reveal the pause button */
            self.pauseButton.state = .MSButtonNodeStateActive
            self.pauseButton2.isHidden = false
            self.pauseButton3.isHidden = false
            
            if (!bumped){
                hero.physicsBody?.velocity.dy = 400
                run(jumpSound)
                bumped = true
            }
            
            /* Grab current velocity */
            let velocityY = hero.physicsBody?.velocity.dy ?? 0
            
            /* Check and cap vertical velocity */
            if velocityY > 400 {
                hero.physicsBody?.velocity.dy = 400
            }
            
            /* Apply falling rotation */
            if sinceTouch > 0.2 {
                let impulse = -20000 * fixedDelta
                hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
            }
            
            /* Update last touch timer */
            sinceTouch += fixedDelta
            
            /* Update obstacle timer */
            spawnTimer += fixedDelta
            
            /* Process world scrolling */
            scrollWorld()
            
            /* Remove offscreen obstacles */
            updateObstacles()
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -5, 30)
        
        /* Clamp position */
        hero.position.y.clamp(v1: CGFloat(-284), CGFloat(284))
        
        /* Clamp velocity */
        hero.physicsBody?.velocity.dx.clamp(v1: 0, 0)
        
        /* Hides the play button */
        if (gameState != .inactive){
            buttonPlay.state = .MSButtonNodeStateHidden
        }
        else {
            hero.position.y = 0
            hero.physicsBody?.velocity.dy.clamp(v1: 0, 0)
        }
        
        /* Updates and displays the high score */
        if points > highScore {
            UserDefaults.standard.set(points, forKey: "HIGHSCORE")
            highScore = UserDefaults().integer(forKey: "HIGHSCORE")
            highScoreLabel.text = "High: \(highScore)"
        }
    }
    
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        scrollLayer2.position.x -= scrollSpeed2 * CGFloat(fixedDelta)
        scrollLayer3.position.x -= scrollSpeed3 * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: groundPosition.x + 2 * (ground.size.width - 1), y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
        
        /* Loop through second scroll layer nodes */
        for crystal in scrollLayer2.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let crystalPosition = scrollLayer2.convert(crystal.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if crystalPosition.x <= -crystal.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: crystalPosition.x + (2 * (crystal.size.width)), y: crystalPosition.y)
                
                /* Convert new node position back to scroll layer space */
                crystal.position = self.convert(newPosition, to: scrollLayer2)
            }
        }
        
        /* Loop through second scroll layer nodes */
        for cloud in scrollLayer3.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let cloudPosition = scrollLayer3.convert(cloud.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: cloudPosition.x + 2 * (cloud.size.width), y: cloudPosition.y)
                
                /* Convert new node position back to scroll layer space */
                cloud.position = self.convert(newPosition, to: scrollLayer3)
            }
        }
    }
    
    /* Update Obstacles */
    func updateObstacles() {
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -43 {
                // 26 is one half the width of an obstacle
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        /* Time to spawn a new obstacle */
        if spawnTimer >= 1 {
            
            /* Create a new obstacle by copying the source obstacle */
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 370, y: CGFloat.random(min: 234, max: 382))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact){
        
        /* Ensure only called while game running */
        if gameState != .active { return }
        
        /* Get references to bodies involved in collision */
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Play sound effect */
            run(goalSound)
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            /* We can return now */
            return
        }
        
        /* Plays sound effect */
        run(deathSound)
        
        /* Change game state to game over */
        gameState = .gameOver
        
        /* Hide pause button */
        pauseButton.state = .MSButtonNodeStateHidden
        pauseButton2.isHidden = true
        pauseButton3.isHidden = true
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        
        /* Create our hero death action */
        let heroDeath = SKAction.run({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        /* Run action */
        hero.run(heroDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            if node != buttonRestart{
                /* Apply effect each ground node */
                node.run(shakeScene)
            }
        }
        
        /* Show restart button */
        buttonRestart.state = .MSButtonNodeStateActive
    }
}
