//
//  GameResultFetcher.swift
//  Traffic-Devils-Test-App
//
//  Created by Georgie Muler on 28.02.2024.
//

import Foundation

class GameResultFetcher {
    func fetchWinnerLoserURLs(from url: URL, completion: @escaping (Result<(winner: String, loser: String), Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "NoData", code: 1, userInfo: nil)
                completion(.failure(noDataError))
                return
            }

            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(WinnerLoser.self, from: data)
                completion(.success((winner: result.winner, loser: result.loser)))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
