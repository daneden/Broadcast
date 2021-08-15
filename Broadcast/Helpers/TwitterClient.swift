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

let typeaheadToken = "AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

class TwitterClient: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  let draftsStore = PersistanceController.shared
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
    
    client.showUser(.id(userId), tweetMode: .extended) { json in
      /** If the `showUser` call was successful, we can reuse the result to update the user’s profile photo */
      guard let urlString = json["profile_image_url_https"].string else {
        return
      }
      
      withAnimation {
        self.user?.originalProfileImageURL = URL(string: urlString.replacingOccurrences(of: "_normal", with: ""))
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
    
    if let mediaData = draft.media?.jpegData(compressionQuality: 0.8) {
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
    
    if let mediaData = draft.media?.jpegData(compressionQuality: 0.8) {
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
    lastTweet.text = json["full_text"].string ?? json["text"].string
    lastTweet.likes = json["favorite_count"].integer
    lastTweet.retweets = json["retweet_count"].integer
    lastTweet.numericId = json["id"].integer
    
    self.getReplies(for: lastTweet) { replies in
      lastTweet.replies = replies
      self.lastTweet = lastTweet
    }
  }
  
  /// Asynchronously update client state on the main thread
  /// - Parameter newState: The new state for the client
  private func updateState(_ newState: State) {
    DispatchQueue.main.async {
      self.state = newState
    }
  }
  
  @Published var userSearchResults: [User]?
  private var userSearchCancellables = [AnyCancellable]()
  func searchScreenNames(_ screenName: String) {
    let url = URL(string: "https://twitter.com/i/search/typeahead.json?count=10&q=%23\(screenName)&result_type=users")!
    
    var headers = [
      "Authorization": typeaheadToken
    ]
    
    if let userId = user?.id,
       let token = client.client.credential?.accessToken?.key {
      headers["Cookie"] = "twid=u%3D\(userId);auth_token=\(token)"
    }
    
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = headers
    request.httpShouldHandleCookies = true
    
    URLSession.shared.dataTaskPublisher(for: request)
      .tryMap() { element -> Data in
        guard let httpResponse = element.response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
        return element.data
      }
      .decode(type: TypeaheadResponse.self, decoder: JSONDecoder())
      .sink { completion in
        switch completion {
        case .failure(let error):
          print(error.localizedDescription)
        default:
          return
        }
      } receiveValue: { result in
        DispatchQueue.main.async {
          self.userSearchResults = result.users
        }
      }.store(in: &userSearchCancellables)
  }
  
  /// Asynchronously provides up to 200 replies for the given tweet. This method works by fetching the
  /// most recent 200 @mentions for the user and filters the result to those replying to the provided tweet.
  /// - Parameters:
  ///   - tweet: The tweet to fetch replies for
  ///   - completion: A callback for handling the replies
  private func getReplies(for tweet: Tweet, completion: @escaping ([Tweet]) -> Void = { _ in }) {
    let formatter = DateFormatter()
    formatter.dateFormat = "EE MMM dd HH:mm:ss Z yyyy"
    
    guard let tweetId = tweet.id else { return }
    
    client.getMentionsTimelineTweets(count: 200, tweetMode: .extended) { json in
      guard let repliesResult = json.array else { return }
      let repliesToThisTweet: [Tweet?] = repliesResult.filter { json in
        guard let replyId = json["in_reply_to_status_id"].integer else { return false }
        return replyId == tweet.numericId
      }.map { json in
        guard let id = json["id_str"].string,
              let text = json["full_text"].string,
              let dateString = json["created_at"].string,
              let date = formatter.date(from: dateString) else {
          return nil
        }
        
        let user = User(from: json["user"])
        return Tweet(id: id, text: text, date: date, author: user)
      }
      
      completion(repliesToThisTweet.compactMap { $0 })
      
    } failure: { error in
      print("Error fetching replies for Tweet with ID \(tweetId)")
      print(error.localizedDescription)
    }
  }
}

/* MARK: Drafts */
extension TwitterClient {
  /// Saves the current draft to CoreData for later retrieval. This method also resets/clears the current draft.
  func saveDraft() {
    guard draft.isValid else { return }
    let copy = draft
    
    DispatchQueue.global(qos: .default).async {
      let newDraft = Draft.init(context: self.draftsStore.context)
      newDraft.date = Date()
      newDraft.text = copy.text
      newDraft.media = copy.media?.fixedOrientation.pngData()
      newDraft.id = UUID()
      
      self.draftsStore.save()
    }
    
    withAnimation {
      self.draft = .init()
      self.state = .idle
    }
  }
  
  /// Retrieve the specified draft from CoreData, storing it in memory and deleting it from the CoreData database
  /// - Parameter draft: The chosen draft for retrieval and deletion
  func retreiveDraft(draft: Draft) {
    withAnimation {
      self.draft = Tweet(text: draft.text)
      
      if let media = draft.media {
        self.draft.media = UIImage(data: media)
      }
    }
    
    let managedObjectContext = PersistanceController.shared.context
    managedObjectContext.delete(draft)

    PersistanceController.shared.save()
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
  
  struct User: Decodable {
    var id: String
    var screenName: String
    var name: String?
    var originalProfileImageURL: URL?
    var profileImageURL: URL? {
      if let urlString = originalProfileImageURL?.absoluteString.replacingOccurrences(of: "_normal", with: "_x96") {
        return URL(string: urlString)
      } else {
        return originalProfileImageURL
      }
    }
    
    enum CodingKeys: String, CodingKey {
      case screenName = "screen_name"
      case originalProfileImageURL = "profile_image_url_https"
      case id = "id_str"
      case name
    }
  }
  
  struct Tweet {
    var numericId: Int?
    var id: String?
    var text: String?
    var media: UIImage?
    
    var likes: Int?
    var retweets: Int?
    var replies: [Tweet]?
    
    var date: Date?
    
    var length: Int {
      TwitterText.tweetLength(text: text ?? "")
    }
    
    var isValid: Bool {
      if media != nil {
        return true
      }
      
      return 1...280 ~= length && !(text ?? "").isBlank
    }
    
    var author: User?
  }
}

extension TwitterClient.User {
  init(from json: JSON) {
    self.name = json["name"].string
    self.screenName = json["screen_name"].string ?? "TwitterUser"
    self.id = json["id_str"].string ?? ""
    let imageUrlString = json["profile_image_url_https"].string ?? ""
    self.originalProfileImageURL = URL(string: imageUrlString)
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

struct TypeaheadResponse: Decodable {
  var num_results: Int
  var users: [TwitterClient.User]?
}
