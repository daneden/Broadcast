//
//  SignInViewModel.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import Swifter
import SwiftKeychainWrapper

class TwitterClient: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  struct ClientCredentials {
    static let APIKey = "GurUHgLj8PQAW8LAe5HyF3Sv3"
    static let APIKeySecret = "GunGXzU48ETjidrzbsq5fRpt6JPrQmlR0H6a77NCAolBUhFp5W"
    static let CallbackURLScheme = "twitter-broadcast"
  }
  
  enum SessionState: Hashable {
    case idle
    case error
    case busy
  }
  
  struct User: Identifiable {
    let id: String
    let screenName: String
  }
  
  @Published var state: SessionState = .idle
  @Published var user: User?
  @Published var tweet: String?
  @Published var image: UIImage?
  
  override init() {
    super.init()
    
    if let credentials = retrieveCredentials() {
      client.client.credential = .init(accessToken: credentials)
      
      if let userID = credentials.userID, let screenName = credentials.screenName {
        user = User(id: userID, screenName: screenName)
      }
    }
  }
  
  private let client = Swifter(
    consumerKey: ClientCredentials.APIKey,
    consumerSecret: ClientCredentials.APIKeySecret
  )
  
  private let callbackURL = URL(string: "\(ClientCredentials.CallbackURLScheme)://")
  
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  func signIn() {
    DispatchQueue.main.async {
      self.state = .busy
    }
    
    client.authorize(withProvider: self, callbackURL: callbackURL!) { result, response in
      if let result = result {
        self.storeCredentials(credentials: result)
      }
      
      DispatchQueue.main.async {
        if let screenName = result?.screenName,
           let id = result?.userID {
          self.user = User(id: id, screenName: screenName)
          self.state = .idle
        } else {
          self.state = .error
        }
      }
    }
  }
  
  func sendTweet(tweet: String, media: Data? = nil) {
    DispatchQueue.main.async {
      self.state = .busy
    }
    
    if let media = media {
      client.postTweet(status: tweet, media: media) { result in
        DispatchQueue.main.async {
          self.state = .idle
          self.image = nil
          self.tweet = nil
        }
      } failure: { error in
        print(error.localizedDescription)
        DispatchQueue.main.async { self.state = .error }
      }
    } else {
      client.postTweet(status: tweet) { result in
        DispatchQueue.main.async {
          self.state = .idle
          self.tweet = nil
        }
      } failure: { error in
        DispatchQueue.main.async { self.state = .error }
      }
    }
  }
  
  private func storeCredentials(credentials: Credential.OAuthAccessToken) {
    guard let encoded = try? JSONEncoder().encode(credentials.asStringDictionary) else { return }
    let success = KeychainWrapper.standard.set(encoded, forKey: "credentials")
    
    print(success ? "Successfully stored credentials" : "Unable to store credentials")
  }
  
  private func retrieveCredentials() -> Credential.OAuthAccessToken? {
    guard let data = KeychainWrapper.standard.data(forKey: "credentials") else { return nil }
    
    guard let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
      return nil
    }
    
    guard let key = dict["key"],
          let secret = dict["secret"],
          let screenName = dict["screenName"],
          let userID = dict["userID"] else {
      return nil
    }
    
    return Credential.OAuthAccessToken(queryString: "oauth_token=\(key)&oauth_token_secret=\(secret)&user_id=\(userID)&screen_name=\(screenName)")
  }
  
  func signOut() {
    KeychainWrapper.standard.remove(forKey: "credentials")
    DispatchQueue.main.async {
      self.client.client.credential = nil
      self.user = nil
      self.image = nil
      self.tweet = nil
    }
  }
}

extension Credential.OAuthAccessToken {
  var asStringDictionary: [String: String] {
    let mirror = Mirror(reflecting: self)
    let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label: String?, value: Any) -> (String, String)? in
      guard let label = label else { return nil }
      
      let subject = Mirror(reflecting: value)
      
      if subject.displayStyle == .optional {
        guard let unwrappedValue = value as? String else { return nil }
        return (label, unwrappedValue)
      } else {
        guard let value = value as? String else { return nil }
        return (label, value)
      }
    }).compactMap { $0 })
    return dict
  }
}
