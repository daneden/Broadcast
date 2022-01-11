//
//  TestAuthenticationProvider.swift
//  Broadcast
//
//  Created by Daniel Eden on 10/01/2022.
//

import Foundation
import AuthenticationServices
import SwiftUI
import CommonCrypto
import SwiftKeychainWrapper

struct UserCredentials: Identifiable, Codable {
  typealias ID = Int
  var id: ID
  var screenName: String
  var oauthToken: String
  var oauthTokenSecret: String
  
  enum CodingKeys: String, CodingKey {
    case id = "user_id"
    case screenName = "screen_name"
    case oauthToken = "oauth_token"
    case oauthTokenSecret = "oauth_token_secret"
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let tempID = try values.decode(String.self, forKey: .id)
    guard let intID = Int(tempID) else {
      throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: [], debugDescription: "Could not encode ID as Int"))
    }
    id = intID
    screenName = try values.decode(String.self, forKey: .screenName)
    oauthToken = try values.decode(String.self, forKey: .oauthToken)
    oauthTokenSecret = try values.decode(String.self, forKey: .oauthTokenSecret)
  }
}

extension UserCredentials.ID {
  var keychainIdentifier: String {
    "broadcast-credentials-\(self)"
  }
}

typealias UserIDsArray = Set<Int>

extension UserIDsArray: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(UserIDsArray.self, from: data) else {
            return nil
          }
    
    self = result
  }
  
  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8) else {
            return "[]"
          }
    
    return result
  }
}

struct OAuthToken: Codable {
  var key: String
  var secret: String
}

@MainActor
class Twift: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  var clientCredentials: OAuthToken
  var userCredentials: OAuthToken?
  var callbackURL: URL
  
  init(clientCredentials: OAuthToken, userCredentials: OAuthToken?, callbackURL: URL) {
    self.clientCredentials = clientCredentials
    self.userCredentials = userCredentials
    self.callbackURL = callbackURL
  }
  
  @AppStorage("authenticatedUserIDs") var authenticatedUserIDs: UserIDsArray = []
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  func userIsAuthorized(userID: UserCredentials.ID) async -> Bool {
    do {
      var urlRequest = URLRequest(url: URL(string: "https://api.twitter.com/2/users/me")!)
      try signRequest(&urlRequest, method: "GET")
      
      let (data, _) = try await URLSession.shared.data(for: urlRequest)
      
      print(String(data: data, encoding: .utf8))
      return true
    } catch {
      print(error.localizedDescription)
      return false
    }
  }
  
  /// Signs a URL request with the necessary authorization headers for a given user
  /// - Parameters:
  ///   - urlRequest: The URL request to sign
  ///   - userID: The user's ID
  ///   - method: HTTP method for the request
  ///   - body: The body for the request
  ///   - contentType: The content type for the request
  /// - Returns: The signed URL request
  func signRequest(_ urlRequest: inout URLRequest,
                   method: String,
                   body: Data? = nil,
                   contentType: String? = nil
  ) throws {
    guard let userCredentials = userCredentials else {
      throw RequestSigningError.MissingCredentials
    }

    urlRequest.oAuthSign(
      method: method,
      body: body,
      contentType: contentType,
      consumerCredentials: (key: clientCredentials.key, secret: clientCredentials.secret),
      userCredentials: (key: userCredentials.key, secret: userCredentials.secret)
    )
  }
  
  /// Requests authorization via Twitter's three-step OAuth flow and stores user credentials for later use
  func requestAuthentication() async throws {
    guard let callback = callbackURL.scheme else {
      throw TwiftError.CallbackURLError
    }
    
    // MARK:  Step one: Obtain a request token
    var stepOneRequest = URLRequest(url: URL(string: "https://api.twitter.com/oauth/request_token")!)
    
    stepOneRequest.oAuthSign(
      method: "POST",
      urlFormParameters: ["oauth_callback" : callback],
      consumerCredentials: (key: clientCredentials.key, secret: clientCredentials.secret)
    )
    
    var oauthToken: String = ""
    
    do {
      let (requestTokenData, _) = try await URLSession.shared.data(for: stepOneRequest)
      
      guard let response = String(data: requestTokenData, encoding: .utf8)?.urlQueryStringParameters,
      let token = response["oauth_token"] else {
        return
      }
      
      oauthToken = token
    } catch {
      print(error.localizedDescription)
    }
    
    // MARK:  Step two: Redirecting the user
    let authURL = URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(oauthToken)")!
    
    let authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "https") { (url, error) in
      if let error = error {
        print(error.localizedDescription)
      } else if let url = url {
        guard let queryItems = url.query?.urlQueryStringParameters,
        let oauthToken = queryItems["oauth_token"],
        let oauthVerifier = queryItems["oauth_verifier"] else {
          return
        }
        
        // MARK:  Step three: Converting the request token into an access token
        Task {
          var stepThreeRequest = URLRequest(url: URL(string: "https://api.twitter.com/oauth/access_token?oauth_verifier=\(oauthVerifier)")!)
          
          stepThreeRequest.oAuthSign(
            method: "POST",
            urlFormParameters: ["oauth_token" : oauthToken],
            consumerCredentials: (key: self.clientCredentials.key, secret: self.clientCredentials.secret)
          )
          
          let (data, _) = try await URLSession.shared.data(for: stepThreeRequest)
          
          guard let response = String(data: data, encoding: .utf8)?.urlQueryStringParameters,
                let encoded = try? JSONEncoder().encode(response) else {
            print("Failed to decode step three response: \(data.description)")
            return
          }
          
          do {
            let user = try JSONDecoder().decode(UserCredentials.self, from: encoded)
            KeychainWrapper.standard.set(encoded, forKey: user.id.keychainIdentifier)
            self.authenticatedUserIDs.insert(user.id)
          } catch {
            print(error)
          }
        }
      }
    }
    
    authSession.presentationContextProvider = self
    authSession.start()
  }
}

extension String {
  var urlEncoded: String {
    var charset: CharacterSet = .urlQueryAllowed
    charset.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
    return self.addingPercentEncoding(withAllowedCharacters: charset)!
  }
}

extension String {
  var urlQueryStringParameters: Dictionary<String, String> {
    // breaks apart query string into a dictionary of values
    var params = [String: String]()
    let items = self.split(separator: "&")
    for item in items {
      let combo = item.split(separator: "=")
      if combo.count == 2 {
        let key = "\(combo[0])"
        let val = "\(combo[1])"
        params[key] = val
      }
    }
    return params
  }
}

extension Twift {
  enum RequestSigningError: Error {
    case DecodingError
    case MissingCredentials
  }
  
  enum TwiftError: Error {
    case CallbackURLError
  }
}
