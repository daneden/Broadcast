//
//  TwitterClient.swift
//  Broadcast
//
//  Created by Daniel Eden on 30/06/2021.
//

import Foundation
import Combine
import Twift
import TwitterText
import UIKit
import AuthenticationServices
import SwiftKeychainWrapper
import SwiftUI

let typeaheadToken = "AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

class TwitterClient: ObservableObject {
  let draftsStore = PersistanceController.shared
  @Published var user: User?
  @Published var draft: MutableTweet = .init()
  @Published var state: State = .initializing
  @Published var lastTweet: Tweet?
  @Published var client: Twift?
  
  @MainActor
  init() {
    if let storedCredentials = self.retreiveCredentials() {
      let newClient = Twift(.userAccessTokens(
        clientCredentials: ClientCredentials.credentials,
        userCredentials: storedCredentials
      ))
      
      Task(priority: .userInitiated) {
        await self.updateClient(newClient)
        withAnimation(.springAnimation) { self.state = .idle }
      }
    } else {
      withAnimation(.springAnimation) { self.state = .idle }
    }
  }
  
  @MainActor
  private func updateClient(_ client: Twift?) async {
    if let client = client {
      self.user = try? await client.getMe(fields: [\.profileImageUrl]).data
      self.lastTweet = try? await client.userTimeline(fields: [\.createdAt, \.publicMetrics]).data.first
    }
  }
  
  @MainActor
  func signIn() {
    self.state = .busy
    
    Twift.Authentication().requestUserCredentials(clientCredentials: ClientCredentials.credentials,
                                                  callbackURL: ClientCredentials.callbackURL) { (userCredentials, error) in
      Task.detached {
        if let userCredentials = userCredentials {
          let newClient = await Twift(.userAccessTokens(clientCredentials: ClientCredentials.credentials, userCredentials: userCredentials))
          await self.updateClient(newClient)
          self.storeCredentials(credentials: userCredentials)
        } else if let error = error {
          print(error)
        }
        
        
        self.state = .idle
      }
    }
  }
  
  func signOut() {
    self.user = nil
    self.draft = .init()
    self.lastTweet = nil
    KeychainWrapper.standard.remove(forKey: "broadcast-credentials")
  }
  
  func storeCredentials(credentials: OAuthCredentials) {
    guard let data = try? JSONEncoder().encode(credentials) else {
      return
    }
    
    KeychainWrapper.standard.set(data, forKey: "broadcast-credentials")
  }
  
  func retreiveCredentials() -> OAuthCredentials? {
    // TODO: Fix test environment
    //    if isTestEnvironment {
    //      return .init(queryString: ClientCredentials.__authQueryString)
    //    }
    guard let data = KeychainWrapper.standard.data(forKey: "broadcast-credentials") else {
      return nil
    }
    
    return try? JSONDecoder().decode(OAuthCredentials.self, from: data)
  }
  
  private func sendTweetCallback(response: TwitterAPIData<PostTweetResponse>? = nil, error: Error? = nil) {
    if response != nil {
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
  
  func sendTweet(asReply: Bool = false) async {
    updateState(.busy)
    if asReply, let lastTweet = lastTweet {
      draft.reply = .init(inReplyToTweetId: lastTweet.id)
    }
    
    let result = try? await client?.postTweet(draft)
    
    if let result = result {
      self.lastTweet = try? await client?.getTweet(result.data.id).data
      sendTweetCallback(response: result, error: nil)
    } else {
      sendTweetCallback(response: nil, error: nil)
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
  func searchScreenNames(_ screenName: String) async {
    let url = URL(string: "https://twitter.com/i/search/typeahead.json?count=10&q=%23\(screenName)&result_type=users")!
    
    var headers = [
      "Authorization": typeaheadToken
    ]
    
    // TODO: Fix user auth for typeahead search
//    if let userId = user?.id,
//       let token = ClientCredentials.credentials.key {
//      headers["Cookie"] = "twid=u%3D\(userId);auth_token=\(token)"
//    }
    
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = headers
    request.httpShouldHandleCookies = true
    
    do {
      let (result, _) = try await URLSession.shared.data(for: request)
      let decodedResult = try JSONDecoder().decode(TypeaheadResponse.self, from: result)
      self.userSearchResults = decodedResult.users
    } catch {
      print(error)
    }
  }
  
  /// Asynchronously provides up to 200 replies for the given tweet. This method works by fetching the
  /// most recent 200 @mentions for the user and filters the result to those replying to the provided tweet.
  /// - Parameters:
  ///   - tweet: The tweet to fetch replies for
  ///   - completion: A callback for handling the replies
  private func getReplies(for tweetId: Tweet.ID) async -> [Tweet] {
    let mentions = try? await client?.userMentions(fields: [\.authorId, \.publicMetrics, \.createdAt, \.referencedTweets],
                                                   expansions: [.authorId(userFields: [\.profileImageUrl])],
                                                   sinceId: tweetId,
                                                   maxResults: 100)
    
    let repliesToTweet = mentions?.data
      .filter { $0.referencedTweets?.contains(where: { $0.id == tweetId }) ?? false } ?? []
    let replyAuthors = mentions?.includes?.users?
      .filter { user in repliesToTweet.contains(where: { $0.authorId == user.id }) } ?? []
    
    return repliesToTweet
  }
}

/* MARK: Drafts */
extension TwitterClient {
  public func draftIsValid() -> Bool {
    if let text = draft.text, !text.isEmpty {
      return TwitterText.remainingCharacterCount(text: text) >= 0
    } else if draft.media != nil {
      return true
    } else {
      return false
    }
  }
  /// Saves the current draft to CoreData for later retrieval. This method also resets/clears the current draft.
  func saveDraft() {
    guard draftIsValid() else { return }
    
    let copy = draft
    DispatchQueue.global(qos: .default).async {
      let newDraft = Draft.init(context: self.draftsStore.context)
      newDraft.date = Date()
      newDraft.text = copy.text
      // TODO: Fix draft media
      //newDraft.media = copy.media?.fixedOrientation.pngData()
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
      self.draft = MutableTweet(text: draft.text)
      
      // TODO: Fix draft media
//      if let media = draft.media {
//        self.draft.media = UIImage(data: media)
//      }
    }
    
    let managedObjectContext = PersistanceController.shared.context
    managedObjectContext.delete(draft)
    
    PersistanceController.shared.save()
  }
}

// MARK: Models
extension TwitterClient {
  enum State: Equatable {
    case idle, busy, initializing
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
    
    static var credentials: OAuthCredentials {
      .init(key: apiKey, secret: apiSecret)
    }
    
    static var __authQueryString: String {
      guard let value = plist?.object(forKey: "__TEST_AUTH_QUERY_STRING") as? String else {
        fatalError("Couldn't find key '__TEST_AUTH_QUERY_STRING' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var callbackProtocol = "twitter-broadcast://"
    static var callbackURL: URL {
      URL(string: callbackProtocol)!
    }
  }
}

struct TypeaheadResponse: Decodable {
  var num_results: Int
  var users: [User]?
}
