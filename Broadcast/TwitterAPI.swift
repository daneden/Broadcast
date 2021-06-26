//
//  TwitterAPI.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import Combine
import Swifter

class TwitterAPI: NSObject, ObservableObject {
  struct ClientCredentials {
    static let APIKey = "GurUHgLj8PQAW8LAe5HyF3Sv3"
    static let APIKeySecret = "GunGXzU48ETjidrzbsq5fRpt6JPrQmlR0H6a77NCAolBUhFp5W"
    static let CallbackURLScheme = "twitter-broadcast"
  }
  
  static var callbackURL: URL {
    URL(string: "\(ClientCredentials.CallbackURLScheme)://")!
  }
  
  @Published var authorizationSheetIsPresented = false
  @Published var authorizationURL: URL?
  @Published var user: User?
  
  struct User {
    let ID: String
    let screenName: String
  }
  
  private let client = Swifter(consumerKey: ClientCredentials.APIKey, consumerSecret: ClientCredentials.APIKeySecret)
  
  func authorize() {
    client.authorizeAppOnly { result, response in
      guard let result = result else {
        return
      }
      
      self.user = User(ID: result.userID!, screenName: result.screenName!)
    } failure: { error in
      print(error.localizedDescription)
    }

  }
  
  func sendTweet(text: String) {
    client.postTweet(status: text)
  }
}
