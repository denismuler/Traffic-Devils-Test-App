//
//  GameViewController.swift
//  Traffic-Devils-Test-App
//
//  Created by Georgie Muler on 26.02.2024.
//

import UIKit
import SpriteKit
import GameplayKit
import WebKit

class GameViewController: UIViewController, GameSceneDelegate {
    
    private var customView: SKView?
    private let url = "https://2llctw8ia5.execute-api.us-west-1.amazonaws.com/prod"
    private var winnerURL: String?
    private var loserURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        
        setupCustomView()
        loadGameResultURLs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (customView?.scene as? GameScene)?.isPaused = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        (customView?.scene as? GameScene)?.startGame()
    }
    
    
    private func setupCustomView() {
        customView = SKView(frame: self.view.frame)
        customView = SKView(frame: view.frame)
        
        if let customView = customView {
            view.addSubview(customView)
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            scene.gameDelegate = self
            customView.presentScene(scene)
        }
    }
    
    private func loadGameResultURLs() {
        guard let url = URL(string: url) else { return }
        
        let dataFetcher = GameResultFetcher()
        dataFetcher.fetchWinnerLoserURLs(from: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let urls):
                self.winnerURL = urls.winner
                self.loserURL = urls.loser
                
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func showWBView(win: Bool) {
        guard let url = win ? winnerURL : loserURL else { return }
        let webViewVC = WebViewViewController(urlString: url)
        let navCon = UINavigationController(rootViewController: webViewVC)
        navCon.modalPresentationStyle = .fullScreen
        navCon.navigationBar.backgroundColor = .systemBackground
        present(navCon, animated: true, completion: nil)
    }
}
