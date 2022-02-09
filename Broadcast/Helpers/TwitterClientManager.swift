//
//  TwitterClientManager.swift
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
import PhotosUI

let typeaheadToken = "AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

typealias AuthenticatedIds = [User.ID]

extension AuthenticatedIds: RawRepresentable {
  public typealias RawValue = String
  public init?(rawValue: RawValue) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(AuthenticatedIds.self, from: data) else {
            return nil
          }
    
    self = result
  }
  
  public var rawValue: RawValue {
    guard let encoded = try? JSONEncoder().encode(self),
          let result = String(data: encoded, encoding: .utf8) else {
            return "[]"
          }
    
    return result
  }
}

class TwitterClientManager: ObservableObject {
  let draftsStore = PersistanceController.shared
  @Published var user: User?
  @Published var draft: MutableTweet = .init()
  @Published var state: State = .initializing
  @Published var lastTweet: Tweet?
  @Published var client: Twift?
  
  @Published var selectedMedia: [String: NSItemProvider] = [:]
  @Published var mediaAltText: [String: String] = [:]
  
  @Published var uploadProgress = Progress()
  
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
  private func updateClient(_ client: Twift?, animated: Bool = false) async {
    guard let client = client else { return }
    
    self.client = client
    let user = try? await client.getMe(fields: [\.profileImageUrl]).data
    let lastTweet = try? await client.userTimeline(fields: [\.createdAt, \.publicMetrics]).data.first
    
    if animated {
      withAnimation {
        self.user = user
        self.lastTweet = lastTweet
      }
    } else {
      self.user = user
      self.lastTweet = lastTweet
    }
  }
  
  @MainActor
  func signIn() async {
    self.updateState(.busy())
    
    let client: Twift? = await withUnsafeContinuation { continuation in
      Twift.Authentication().requestUserCredentials(clientCredentials: ClientCredentials.credentials,
                                                    callbackURL: ClientCredentials.callbackURL) { (userCredentials, error) in
        if let userCredentials = userCredentials {
          let newClient = Twift(.userAccessTokens(clientCredentials: ClientCredentials.credentials, userCredentials: userCredentials))
          self.storeCredentials(credentials: userCredentials)
          continuation.resume(returning: newClient)
        } else if let error = error {
          print(error)
          continuation.resume(returning: nil)
        }
      }
    }
    
    await self.updateClient(client, animated: true)
    self.updateState(.idle)
  }
  
  @MainActor
  func signOut() {
    self.user = nil
    self.draft = .init()
    self.lastTweet = nil
    self.client = nil
    KeychainWrapper.standard.remove(forKey: "broadcast-credentials")
  }
  
  func storeCredentials(credentials: OAuthCredentials) {
    guard let data = try? JSONEncoder().encode(credentials) else {
      return
    }
    
    KeychainWrapper.standard.set(data, forKey: "broadcast-credentials")
  }
  
  func retreiveCredentials() -> OAuthCredentials? {
    if isTestEnvironment {
      return ClientCredentials.userCredentials
    }
    guard let data = KeychainWrapper.standard.data(forKey: "broadcast-credentials") else {
      return nil
    }
    
    return try? JSONDecoder().decode(OAuthCredentials.self, from: data)
  }
  
  private func sendTweetCallback(response: TwitterAPIData<PostTweetResponse>? = nil, error: Error? = nil) {
    if response != nil {
      self.updateState(.idle)
      self.draft = .init()
      withAnimation { self.selectedMedia = [:] }
      Haptics.shared.sendStandardFeedback(feedbackType: .success)
    } else if let error = error {
      print(error.localizedDescription)
      
      if !self.selectedMedia.isEmpty {
        self.updateState(.genericTextAndMediaError)
      } else {
        self.updateState(.genericTextError)
      }
      
      Haptics.shared.sendStandardFeedback(feedbackType: .error)
    }
  }
  
  @MainActor
  func sendTweet(asReply: Bool = false) async {
    guard let client = self.client else {
      return
    }
    
    updateState(.busy())
    
    do {
      if asReply, let lastTweet = lastTweet {
        draft.reply = .init(inReplyToTweetId: lastTweet.id)
      }
      
      var mediaStrings: [String] = []
      for (key, media) in selectedMedia {
        
        let media: (Data, String)? = await withUnsafeContinuation { continuation in
          var utType: UTType
          
          if media.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            utType = media.mediaType ?? .image
          } else if media.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            utType = media.mediaType ?? .movie
          } else {
            return continuation.resume(returning: nil)
          }
          
          guard let mimeTypeString = utType.preferredMIMEType else {
            return continuation.resume(returning: nil)
          }
          
          media.loadDataRepresentation(forTypeIdentifier: utType.identifier, completionHandler: { data, error in
            if let error = error {
              print(error)
              return self.sendTweetCallback(response: nil, error: error)
            }
            
            if let data = data {
              continuation.resume(returning: (data, mimeTypeString))
            } else {
              return self.updateState(.error("There was a problem Tweeting the attached media because it's in an unusual format."))
            }
          })
        }
        
        guard let (data, mimeType) = media else {
          return updateState(.genericTextAndMediaError)
        }
        
        let result = try await client.upload(mediaData: data, mimeType: mimeType, progress: &self.uploadProgress)
        
        if let altText = mediaAltText[key] {
          try await client.addAltText(to: result.mediaIdString, text: altText)
        }
        
        if result.processingInfo != nil {
          _ = try await client.checkMediaUploadSuccessful(result.mediaIdString)
        }
        
        mediaStrings.append(result.mediaIdString)
      }
      
      if !mediaStrings.isEmpty {
        draft.media = MutableMedia(mediaIds: mediaStrings)
      }
      
      let result = try await client.postTweet(draft)
      self.lastTweet = try await client.getTweet(result.data.id).data
      sendTweetCallback(response: result, error: nil)
    } catch {
      print(error)
      sendTweetCallback(response: nil, error: error)
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
  
  @MainActor
  func searchScreenNames(_ screenName: String) async {
    let url = URL(string: "https://twitter.com/i/search/typeahead.json?count=10&q=%23\(screenName)&result_type=users")!
    
    var headers = [
      "Authorization": typeaheadToken
    ]
    
    guard case .userAccessTokens(_, let userCredentials) = client?.authenticationType else {
      return
    }
    
    if let userId = user?.id {
      headers["Cookie"] = "twid=u%3D\(userId);auth_token=\(userCredentials.key)"
    }
    
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = headers
    request.httpShouldHandleCookies = true
    
    do {
      let (result, _) = try await URLSession.shared.data(for: request)
      let decodedResult = try JSONDecoder().decode(TypeaheadResponse.self, from: result)
      withAnimation(.easeInOut(duration: 0.2)) {
        self.userSearchResults = decodedResult.users?.compactMap { $0.toUser() }
      }
    } catch {
      print(error)
    }
  }
  
  /// Asynchronously provides up to 200 replies for the given tweet. This method works by fetching the
  /// most recent 200 @mentions for the user and filters the result to those replying to the provided tweet.
  /// - Parameters:
  ///   - tweet: The tweet to fetch replies for
  ///   - completion: A callback for handling the replies
  public func getReplies(for tweetId: Tweet.ID) async -> [(tweet: Tweet, author: User)] {
    let mentions = try? await client?.userMentions(fields: [\.authorId, \.publicMetrics, \.createdAt, \.referencedTweets],
                                                   expansions: [.authorId(userFields: [\.profileImageUrl])],
                                                   sinceId: tweetId,
                                                   maxResults: 100)
    
    let repliesToTweet = mentions?.data
      .filter { $0.referencedTweets?.contains(where: { $0.id == tweetId }) ?? false } ?? []
    let replyAuthors = mentions?.includes?.users?
      .filter { user in repliesToTweet.contains(where: { $0.authorId == user.id }) } ?? []
    
    return repliesToTweet.map { tweet in
      (tweet: tweet, author: replyAuthors.first(where: { $0.id == tweet.authorId! })!)
    }
  }
}

fileprivate struct V1User: Codable {
  let id_str: String
  let name: String
  let screen_name: String
  let profile_image_url_https: URL
  
  func toUser() -> User? {
    let jsonString = """
  {
    "id": "\(id_str)",
    "profileImageUrl": "\(profile_image_url_https)",
    "name": "\(name)",
    "username": "\(screen_name)"
  }
"""
    do {
      return try JSONDecoder().decode(User.self, from: jsonString.data(using: .utf8)!)
    } catch {
      print(error)
      return nil
    }
  }
}

/* MARK: Drafts */
extension TwitterClientManager {
  public func draftIsValid() -> Bool {
    if let text = draft.text, !text.isEmpty && !text.isBlank {
      return TwitterText.tweetLength(text: text) <= 280
    } else if !selectedMedia.isEmpty {
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
extension TwitterClientManager {
  enum State: Equatable {
    case idle, initializing
    case busy(_ progress: Progress? = nil)
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
      guard let value = plist?.object(forKey: "TWITTER_CONSUMER_KEY") as? String else {
        fatalError("Couldn't find key 'TWITTER_CONSUMER_KEY' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var apiSecret: String {
      guard let value = plist?.object(forKey: "TWITTER_CONSUMER_SECRET") as? String else {
        fatalError("Couldn't find key 'TWITTER_CONSUMER_SECRET' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var credentials: OAuthCredentials {
      .init(key: apiKey, secret: apiSecret)
    }
    
    static var callbackProtocol = "twitter-broadcast://"
    static var callbackURL: URL {
      URL(string: callbackProtocol)!
    }
    
    static var accessKey: String {
      guard let value = plist?.object(forKey: "TWITTER_ACCESS_KEY") as? String else {
        fatalError("Couldn't find key 'TWITTER_ACCESS_KEY' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var accessSecret: String {
      guard let value = plist?.object(forKey: "TWITTER_ACCESS_SECRET") as? String else {
        fatalError("Couldn't find key 'TWITTER_ACCESS_SECRET' in 'TwitterAPI-Info.plist'.")
      }
      
      return value
    }
    
    static var userCredentials: OAuthCredentials {
      .init(key: accessKey, secret: accessSecret)
    }
  }
}

fileprivate struct TypeaheadResponse: Decodable {
  var num_results: Int
  var users: [V1User]?
}
