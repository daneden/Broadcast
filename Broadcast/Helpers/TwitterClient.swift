//
//  TwitterClient.swift
//  Broadcast
//
//  Created by Daniel Eden on 30/06/2021.
//

import Foundation
import Combine
import Swifter
import TwitterText
import UIKit
import AuthenticationServices
import SwiftKeychainWrapper

class TwitterClient: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  @Published var user: User?
  @Published var draft = Tweet()
  @Published var state: State = .idle
  
  private var client = Swifter.init(consumerKey: ClientCredentials.apiKey, consumerSecret: ClientCredentials.apiSecret)
  
  override init() {
    super.init()
    
    if let storedCredentials = retreiveCredentials() {
      self.client.client.credential = .init(accessToken: storedCredentials)
      if let userId = storedCredentials.userID,
         let screenName = storedCredentials.screenName {
        DispatchQueue.main.async {
          self.user = .init(id: userId, screenName: screenName)
          self.revalidateAccount()
        }
      }
    }
  }
  
  func signIn() {
    DispatchQueue.main.async { self.state = .busy }
    client.authorize(withProvider: self, callbackURL: ClientCredentials.callbackURL) { credentials, response in
      guard let credentials = credentials,
            let id = credentials.userID,
            let screenName = credentials.screenName else {
        self.state = .error("Yikes, something when wrong when trying to sign in")
        return
      }
      
      self.storeCredentials(credentials: credentials)
      
      DispatchQueue.main.async {
        self.state = .idle
        self.user = User(id: id, screenName: screenName)
        self.revalidateAccount()
      }
    }
  }
  
  func revalidateAccount() {
    DispatchQueue.main.async {
      self.state = .busy
    }
    
    guard let userId = user?.id else {
      self.signOut()
      return
    }
    
    client.showUser(.id(userId)) { json in
      print(json)
      guard let urlString = json["profile_image_url_https"].string else {
        return
      }
      
      self.user?.profileImageURL = URL(string: urlString.replacingOccurrences(of: "_normal", with: ""))
    } failure: { error in
      self.signOut()
      DispatchQueue.main.async {
        self.state = .error("Oh man, there was a problem signing in to Twitter. Maybe try it again.")
      }
    }
  }
  
  func signOut() {
    self.user = nil
    self.draft = .init()
    KeychainWrapper.standard.remove(forKey: "broadcast-credentials")
  }
  
  func storeCredentials(credentials: Credential.OAuthAccessToken) {
    guard let data = credentials.data else {
      return
    }
    
    KeychainWrapper.standard.set(data, forKey: "broadcast-credentials")
  }
  
  func retreiveCredentials() -> Credential.OAuthAccessToken? {
    guard let data = KeychainWrapper.standard.data(forKey: "broadcast-credentials") else {
      return nil
    }
    
    return .init(from: data)
  }
  
  func sendTweet() {
    // TODO
  }
}

extension TwitterClient {
  enum State: Equatable {
    case idle, busy
    case error(_: String?)
  }
  
  struct ClientCredentials {
    static private var plist: NSDictionary? {
      guard let filePath = Bundle.main.path(forResource: "TwitterAPI-Info", ofType: "plist") else {
        fatalError("Couldn't find file 'TwitterAPI-Info.plist'.")
      }
      // 2
      return NSDictionary(contentsOfFile: filePath)
    }
    
    static var apiKey: String {
      guard let value = plist?.object(forKey: "API_KEY") as? String else {
        fatalError("Couldn't find key 'API_KEY' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var apiSecret: String {
      guard let value = plist?.object(forKey: "API_SECRET") as? String else {
        fatalError("Couldn't find key 'API_KEY' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var callbackProtocol = "twitter-broadcast://"
    static var callbackURL: URL {
      URL(string: callbackProtocol)!
    }
  }
  
  struct User {
    var id: String
    var screenName: String
    var profileImageURL: URL?
  }
  
  struct Tweet {
    var text: String?
    var media: UIImage?
    
    var length: Int {
      TwitterText.tweetLength(text: text ?? "")
    }
    
    var isValid: Bool {
      length <= 280
    }
  }
}

extension Credential.OAuthAccessToken {
  var data: Data? {
    let dict = [
      "key": key,
      "secret": secret,
      "userId": userID,
      "screenName": screenName
    ]
    
    return try? JSONSerialization.data(withJSONObject: dict, options: [])
  }
  
  init?(from data: Data) {
    do {
      let dict = try JSONDecoder().decode([String: String].self, from: data)
      guard let key = dict["key"],
            let secret = dict["secret"] else {
        return nil
      }
      
      let screenName = dict["screenName"]
      let userId = dict["userId"]
      
      let queryString = "oauth_token=\(key)&oauth_token_secret=\(secret)&screen_name=\(screenName ?? "")&user_id=\(userId ?? "")"
      
      self.init(queryString: queryString)
    } catch let error {
      print(error.localizedDescription)
      return nil
    }
  }
}
