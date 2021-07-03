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
  
  @AppStorage("drafts") var drafts: Drafts = []
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
    self.lastTweet = nil
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
  
  private func sendTweetCallback(response: JSON? = nil, error: Error? = nil) {
    if let json = response {
      self.updateLastTweet(from: json)
      self.updateState(.idle)
      self.draft = .init()
      Haptics.shared.sendStandardFeedback(feedbackType: .success)
    } else if let error = error {
      print(error.localizedDescription)
      
      if draft.media != nil {
        self.updateState(.genericTextAndMediaError)
      } else {
        self.updateState(.genericTextError)
      }
      
      Haptics.shared.sendStandardFeedback(feedbackType: .error)
    }
  }
  
  func sendTweet() {
    updateState(.busy)
    
    if let mediaData = draft.media {
      client.postTweet(status: draft.text ?? "", media: mediaData) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        print(error.localizedDescription)
        self.sendTweetCallback(error: error)
      }
    } else if let status = draft.text {
      client.postTweet(status: status) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        print(error.localizedDescription)
        self.sendTweetCallback(error: error)
      }
    }
  }
  
  func sendReply(to id: String) {
    updateState(.busy)
    
    if let mediaData = draft.media {
      client.postTweet(status: draft.text ?? "", media: mediaData, inReplyToStatusID: id) { json in
        self.sendTweetCallback(response: json)
      } failure: { error in
        self.sendTweetCallback(error: error)
      }
    } else if let status = draft.text {
      client.postTweet(status: status, inReplyToStatusID: id) { json in
        self.sendTweetCallback(response: json)
        Haptics.shared.sendStandardFeedback(feedbackType: .success)
      } failure: { error in
        self.sendTweetCallback(error: error)
      }
    }
  }
  
  private func updateLastTweet(from json: JSON) {
    guard let id = json["id_str"].string else { return }
    var lastTweet = Tweet(id: id)
    lastTweet.text = json["text"].string
    lastTweet.likes = json["favorite_count"].integer
    lastTweet.retweets = json["retweet_count"].integer
    
    self.lastTweet = lastTweet
    
    self.getReplies(for: lastTweet) { replies in
      self.lastTweet?.replies = replies
    }
  }
  
  private func updateState(_ newState: State) {
    DispatchQueue.main.async {
      self.state = newState
    }
  }
  
  private func getUserTimeline() {
    guard let userId = user?.id else { return }
    client.getTimeline(for: .id(userId)) { json in
      print(json)
    } failure: { error in
      print(error.localizedDescription)
    }
  }
  
  private func getReplies(for tweet: Tweet, completion: @escaping ([Tweet]) -> Void = { _ in }) {
    let formatter = DateFormatter()
    formatter.dateFormat = "EE MMM dd hh:mm:ss Z yyyy"
    
    guard let tweetId = tweet.id else { return }
    client.getMentionsTimelineTweets(count: 200, sinceID: tweetId) { json in
      guard let replies = json.array else { return }
      let repliesToThisTweet: [Tweet?] = replies.filter { json in
        json["in_reply_to_status_id"].string == tweetId
      }.map { json in
        guard let id = json["id_str"].string,
              let text = json["text"].string,
              let dateString = json["created_at"].string,
              let date = formatter.date(from: dateString) else {
          return nil
        }
        
        return Tweet(id: id, text: text, date: date)
      }
      
      completion(repliesToThisTweet.compactMap { $0 })
      
    } failure: { error in
      print("Error fetching replies for Tweet with ID \(tweetId)")
      print(error.localizedDescription)
    }
  }
}

/* MARK: Drafts */
typealias Drafts = Set<TwitterClient.Tweet>

extension Drafts: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(Drafts.self, from: data)
    else {
      return nil
    }
    self = result
  }
  
  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension TwitterClient {
  func saveDraft() {
    guard draft.isValid else { return }
    draft.date = Date()
    
    drafts.insert(draft)
    draft = .init()
  }
  
  func retreiveDraft(draft: Tweet) {
    drafts.remove(draft)
    self.draft = draft
  }
}

// MARK: Models
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
  
  struct Tweet: Hashable, Codable {
    var id: String?
    var text: String?
    var media: Data?
    
    var likes: Int?
    var retweets: Int?
    var replies: [Tweet]?
    
    var date: Date?
    
    var mediaAsUIImage: UIImage? {
      guard let data = media else { return nil }
      return UIImage(data: data)
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
