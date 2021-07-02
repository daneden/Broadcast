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
import SwiftUI

class TwitterClient: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  @Published var user: User?
  @Published var draft = Tweet()
  @Published var state: State = .idle
  @Published var lastTweet: Tweet?
  
  private var client = Swifter.init(consumerKey: ClientCredentials.apiKey, consumerSecret: ClientCredentials.apiSecret)
  
  override init() {
    super.init()
    
    if let storedCredentials = retreiveCredentials() {
      self.client.client.credential = .init(accessToken: storedCredentials)
      if let userId = storedCredentials.userID,
         let screenName = storedCredentials.screenName {
        self.user = .init(id: userId, screenName: screenName)
        self.revalidateAccount()
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
    guard let userId = user?.id else {
      self.signOut()
      return
    }
    
    client.showUser(.id(userId)) { json in
      /** If the `showUser` call was successful, we can reuse the result to update the user’s profile photo */
      guard let urlString = json["profile_image_url_https"].string else {
        return
      }
      
      withAnimation {
        self.user?.profileImageURL = URL(string: urlString.replacingOccurrences(of: "_normal", with: ""))
      }
      
      self.updateLastTweet(from: json["status"])
    } failure: { error in
      self.signOut()
      self.updateState(.error("Yikes; there was a problem signing in to Twitter. You’ll have to try signing in again."))
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
  
  private func sendTweetCallback(response: JSON? = nil, error: Error? = nil, hasMedia: Bool = false) {
    if let json = response {
      self.updateLastTweet(from: json)
      self.updateState(.idle)
      self.draft = .init()
      Haptics.shared.sendStandardFeedback(feedbackType: .success)
    } else {
      if let error = error {
        print(error.localizedDescription)
      }
      
      if hasMedia {
        self.updateState(.genericTextAndMediaError)
      } else {
        self.updateState(.genericTextError)
      }
      
      Haptics.shared.sendStandardFeedback(feedbackType: .error)
    }
  }
  
  func sendTweet() {
    updateState(.busy)
    
    if let media = draft.media,
       let mediaData = media.jpegData(compressionQuality: 80) {
      client.postTweet(status: draft.text ?? "", media: mediaData) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        print(error.localizedDescription)
        self.sendTweetCallback(hasMedia: true)
      }
    } else if let status = draft.text {
      client.postTweet(status: status) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        print(error.localizedDescription)
        self.sendTweetCallback()
      }
    }
  }
  
  func sendReply(to id: String) {
    updateState(.busy)
    
    if let mediaData = draft.mediaData {
      client.postTweet(status: draft.text ?? "", media: mediaData, inReplyToStatusID: id) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        self.sendTweetCallback(error: error, hasMedia: false)
      }
    } else if let status = draft.text {
      client.postTweet(status: status, inReplyToStatusID: id) { json in
        self.sendTweetCallback(response: json)
        Haptics.shared.sendStandardFeedback(feedbackType: .success)
      } failure: { error in
        self.sendTweetCallback(error: error, hasMedia: false)
      }
    }
  }
  
  private func updateLastTweet(from json: JSON) {
    guard let id = json["id_str"].string else { return }
    var lastTweet = Tweet(id: id)
    lastTweet.text = json["text"].string
    
    self.lastTweet = lastTweet
  }
  
  private func updateState(_ newState: State) {
    DispatchQueue.main.async {
      self.state = newState
    }
  }
}

extension TwitterClient {
  enum State: Equatable {
    case idle, busy
    case error(_: String? = nil)
    
    static var genericTextError = State.error("Oh man, something went wrong sending that tweet. It might be too long.")
    static var genericTextAndMediaError = State.error("Oh man, something went wrong sending that tweet. Maybe it’s too long, or your chosen media is causing a problem.")
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
    var id: String?
    var text: String?
    var media: UIImage?
    
    var mediaData: Data? {
      return media?.jpegData(compressionQuality: 80)
    }
    
    var length: Int {
      TwitterText.tweetLength(text: text ?? "")
    }
    
    var isValid: Bool {
      if media != nil {
        return true
      }
      
      return 1...280 ~= length
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
