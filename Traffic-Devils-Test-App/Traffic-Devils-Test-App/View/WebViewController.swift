//
//  WebViewController.swift
//  Traffic-Devils-Test-App
//
//  Created by Georgie Muler on 28.02.2024.
//

import Foundation
import UIKit
import WebKit

class WebViewViewController: UIViewController {
    
    private var webView: WKWebView!
    private var url: URL?
    
    init(urlString: String) {
        super.init(nibName: nil, bundle: nil)
        if let url = URL(string: urlString) {
            self.url = url
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupWebView()
        setupBackButton()
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()

        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0),
            webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            webView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)])

        guard let url = url else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func setupBackButton() {
        let customButton = UIButton(type: .custom)
        customButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        customButton.setTitle("Back", for: .normal)
        customButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        customButton.setTitleColor(customButton.tintColor, for: .normal)
        customButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let backButton = UIBarButtonItem(customView: customButton)

        self.navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        self.dismiss(animated: true)
    }

}
