//
//  TwitterAPI.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import Combine

class TwitterAPI: NSObject, ObservableObject {
  struct ClientCredentials {
    static let APIKey = "GurUHgLj8PQAW8LAe5HyF3Sv3"
    static let APIKeySecret = "GunGXzU48ETjidrzbsq5fRpt6JPrQmlR0H6a77NCAolBUhFp5W"
    static let CallbackURLScheme = "twitter-broadcast"
  }
  
  lazy var onOAuthRedirect = PassthroughSubject<URL, Never>()
  
  @Published var authorizationSheetIsPresented = false
  @Published var authorizationURL: URL?
  @Published var user: User?
  
  struct User {
    let ID: String
    let screenName: String
  }
  
  private var subscriptions: [String: AnyCancellable] = [:]
  private var tokenCredentials: TokenCredentials?
  
  func sendTweet(text: String) {
    var urlComponents = URLComponents(string: "https://api.twitter.com/1.1/statuses/update.json")
    urlComponents?.queryItems = [
      URLQueryItem(name: "status", value: text)
    ]
    
    var request = URLRequest(url: (urlComponents?.url)!)
    
    var parameters = [
      URLQueryItem(name: "oauth_consumer_key", value: ClientCredentials.APIKey),
      URLQueryItem(name: "oauth_nonce", value: UUID().uuidString),
      URLQueryItem(name: "oauth_signature_method", value: "HMAC-SHA1"),
      URLQueryItem(name: "oauth_timestamp", value: String(Int(Date().timeIntervalSince1970))),
      URLQueryItem(name: "oauth_token", value: tokenCredentials?.accessToken),
      URLQueryItem(name: "oauth_version", value: "1.0")
    ]
    
    let signature = oAuthSignature(httpMethod: request.httpMethod!,
                                   baseURLString: request.baseURLString,
                                   parameters: parameters,
                                   consumerSecret: request.consumerSecret,
                                   oAuthTokenSecret: tokenCredentials?.accessTokenSecret)
    
    parameters.append(URLQueryItem(name: "oauth_signature", value: signature))
    
    request.setValue(oAuthAuthorizationHeader(parameters: parameters),
                        forHTTPHeaderField: "Authorization")

    self.subscriptions["sendingTweetSubscriber"] =
      URLSession.shared.dataTaskPublisher(for: request)
      .tryMap { data, response -> (TokenCredentials, User) in
        guard let response = response as? HTTPURLResponse
        else { throw OAuthError.unknown }
        
        guard response.statusCode == 200
        else { throw OAuthError.httpURLResponse(response.statusCode) }
        
        guard let parameterString = String(data: data, encoding: .utf8)
        else { throw OAuthError.cannotDecodeRawData }
        
        if let parameters = parameterString.urlQueryItems {
          guard let oAuthToken = parameters.value(for: "oauth_token"),
                let oAuthTokenSecret = parameters.value(for: "oauth_token_secret"),
                let userID = parameters.value(for: "user_id"),
                let screenName = parameters.value(for: "screen_name")
          else {
            throw OAuthError.unexpectedResponse
          }
          
          return (TokenCredentials(accessToken: oAuthToken,
                                   accessTokenSecret: oAuthTokenSecret),
                  User(ID: userID,
                       screenName: screenName))
        } else {
          throw OAuthError.cannotParseResponse
        }
      }
      .mapError { error -> OAuthError in
        switch (error) {
        case let oAuthError as OAuthError:
          return oAuthError
        default:
          return OAuthError.unknown
        }
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
      .sink(receiveCompletion: { completion in
        print(completion)
      }, receiveValue: { (creds, user) in
        print(creds)
        print(user)
      })
  }
  
  func authorize() {
    guard !self.authorizationSheetIsPresented else { return }
    self.authorizationSheetIsPresented = true
    
    self.subscriptions["oAuthRequestTokenSubscriber"] =
      self.oAuthRequestTokenPublisher()
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished: ()
        case .failure(_):
          print("There was an error receiving temporary credentials")
          self.authorizationSheetIsPresented = false
        }
        self.subscriptions.removeValue(forKey: "oAuthRequestTokenSubscriber")
      }, receiveValue: { [weak self] temporaryCredentials in
        guard let self = self else { return }
        
        guard let authorizationURL = URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(temporaryCredentials.requestToken)")
        else { return }
        
        self.authorizationURL = authorizationURL
        self.subscriptions["onOAuthRedirect"] =
          self.onOAuthRedirect
          .sink(receiveValue: { [weak self] url in
            guard let self = self else { return }
            
            self.subscriptions.removeValue(forKey: "onOAuthRedirect")
            self.authorizationSheetIsPresented = false
            self.authorizationURL = nil
            if let parameters = url.query?.urlQueryItems {
              guard let oAuthToken = parameters["oauth_token"],
                    let oAuthVerifier = parameters["oauth_verifier"]
              else {
                print("There was an error signing in (unexpected response)")
                return
              }
              
              if oAuthToken != temporaryCredentials.requestToken {
                print("There was an error signing in (credentials do not match)")
                return
              }
              
              self.subscriptions["oAuthAccessTokenSubscriber"] =
                self.oAuthAccessTokenPublisher(temporaryCredentials: temporaryCredentials,
                                               verifier: oAuthVerifier)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                  // Error handler
                }, receiveValue: { [weak self] (tokenCredentials, user) in
                  guard let self = self else { return }
                  
                  self.subscriptions.removeValue(forKey: "oAuthRequestTokenSubscriber")
                  self.subscriptions.removeValue(forKey: "onOAuthRedirect")
                  self.subscriptions.removeValue(forKey: "oAuthAccessTokenSubscriber")
                  
                  self.tokenCredentials = tokenCredentials
                  self.user = user
                })
            }
          })
      })
  }
}

extension TwitterAPI {
  struct TokenCredentials {
    let accessToken: String
    let accessTokenSecret: String
  }
}

extension TwitterAPI {
  private func oAuthSignatureBaseString(httpMethod: String,
                                        baseURLString: String,
                                        parameters: [URLQueryItem]) -> String {
    var parameterComponents: [String] = []
    for parameter in parameters {
      let name = parameter.name.oAuthURLEncodedString
      let value = parameter.value?.oAuthURLEncodedString ?? ""
      parameterComponents.append("\(name)=\(value)")
    }
    let parameterString = parameterComponents.sorted().joined(separator: "&")
    return httpMethod + "&" +
      baseURLString.oAuthURLEncodedString + "&" +
      parameterString.oAuthURLEncodedString
  }
}

extension TwitterAPI {
  private func oAuthSigningKey(consumerSecret: String,
                               oAuthTokenSecret: String?) -> String {
    if let oAuthTokenSecret = oAuthTokenSecret {
      return consumerSecret.oAuthURLEncodedString + "&" +
        oAuthTokenSecret.oAuthURLEncodedString
    } else {
      return consumerSecret.oAuthURLEncodedString + "&"
    }
  }
}

extension TwitterAPI {
  private func oAuthSignature(httpMethod: String,
                              baseURLString: String,
                              parameters: [URLQueryItem],
                              consumerSecret: String,
                              oAuthTokenSecret: String? = nil) -> String {
    let signatureBaseString = oAuthSignatureBaseString(httpMethod: httpMethod,
                                                       baseURLString: baseURLString,
                                                       parameters: parameters)
    
    let signingKey = oAuthSigningKey(consumerSecret: consumerSecret,
                                     oAuthTokenSecret: oAuthTokenSecret)
    
    return signatureBaseString.hmacSHA1Hash(key: signingKey)
  }
}

extension TwitterAPI {
  private func oAuthAuthorizationHeader(parameters: [URLQueryItem]) -> String {
    var parameterComponents: [String] = []
    for parameter in parameters {
      let name = parameter.name.oAuthURLEncodedString
      let value = parameter.value?.oAuthURLEncodedString ?? ""
      parameterComponents.append("\(name)=\"\(value)\"")
    }
    return "OAuth " + parameterComponents.sorted().joined(separator: ", ")
  }
}

extension TwitterAPI {
  struct TemporaryCredentials {
    let requestToken: String
    let requestTokenSecret: String
  }
  
  enum OAuthError: Error {
    case unknown
    case urlError(URLError)
    case httpURLResponse(Int)
    case cannotDecodeRawData
    case cannotParseResponse
    case unexpectedResponse
    case failedToConfirmCallback
  }
}

extension TwitterAPI {
  func oAuthRequestTokenPublisher() -> AnyPublisher<TemporaryCredentials, OAuthError> {
    let request = (baseURLString: "https://api.twitter.com/oauth/request_token",
                   httpMethod: "POST",
                   consumerKey: ClientCredentials.APIKey,
                   consumerSecret: ClientCredentials.APIKeySecret,
                   callbackURLString: "\(ClientCredentials.CallbackURLScheme)://")
    
    guard let baseURL = URL(string: request.baseURLString) else {
      return Fail(error: OAuthError.urlError(URLError(.badURL)))
        .eraseToAnyPublisher()
    }
    
    var parameters = [
      URLQueryItem(name: "oauth_callback", value: request.callbackURLString),
      URLQueryItem(name: "oauth_consumer_key", value: request.consumerKey),
      URLQueryItem(name: "oauth_nonce", value: UUID().uuidString),
      URLQueryItem(name: "oauth_signature_method", value: "HMAC-SHA1"),
      URLQueryItem(name: "oauth_timestamp", value: String(Int(Date().timeIntervalSince1970))),
      URLQueryItem(name: "oauth_version", value: "1.0")
    ]
    
    let signature = oAuthSignature(httpMethod: request.httpMethod,
                                   baseURLString: request.baseURLString,
                                   parameters: parameters,
                                   consumerSecret: request.consumerSecret)
    
    parameters.append(URLQueryItem(name: "oauth_signature", value: signature))
    
    var urlRequest = URLRequest(url: baseURL)
    urlRequest.httpMethod = request.httpMethod
    urlRequest.setValue(oAuthAuthorizationHeader(parameters: parameters),
                        forHTTPHeaderField: "Authorization")
    
    return
      URLSession.shared.dataTaskPublisher(for: urlRequest)
      .tryMap { data, response -> TemporaryCredentials in
        guard let response = response as? HTTPURLResponse
        else { throw OAuthError.unknown }
        
        guard response.statusCode == 200
        else { throw OAuthError.httpURLResponse(response.statusCode) }
        
        guard let parameterString = String(data: data, encoding: .utf8)
        else { throw OAuthError.cannotDecodeRawData }
        
        if let parameters = parameterString.urlQueryItems {
          guard let oAuthToken = parameters["oauth_token"],
                let oAuthTokenSecret = parameters["oauth_token_secret"],
                let oAuthCallbackConfirmed = parameters["oauth_callback_confirmed"]
          else {
            throw OAuthError.unexpectedResponse
          }
          
          if oAuthCallbackConfirmed != "true" {
            throw OAuthError.failedToConfirmCallback
          }
          
          return TemporaryCredentials(requestToken: oAuthToken,
                                      requestTokenSecret: oAuthTokenSecret)
        } else {
          throw OAuthError.cannotParseResponse
        }
      }
      .mapError { error -> OAuthError in
        switch (error) {
        case let oAuthError as OAuthError:
          return oAuthError
        default:
          return OAuthError.unknown
        }
      }
      .eraseToAnyPublisher()
  }
}

extension TwitterAPI {
  func oAuthAccessTokenPublisher(temporaryCredentials: TemporaryCredentials, verifier: String) -> AnyPublisher<(TokenCredentials, User), OAuthError> {
    let request = (baseURLString: "https://api.twitter.com/oauth/access_token",
                   httpMethod: "POST",
                   consumerKey: ClientCredentials.APIKey,
                   consumerSecret: ClientCredentials.APIKeySecret)
    
    guard let baseURL = URL(string: request.baseURLString) else {
      return Fail(error: OAuthError.urlError(URLError(.badURL)))
        .eraseToAnyPublisher()
    }
    
    var parameters = [
      URLQueryItem(name: "oauth_token", value: temporaryCredentials.requestToken),
      URLQueryItem(name: "oauth_verifier", value: verifier),
      URLQueryItem(name: "oauth_consumer_key", value: request.consumerKey),
      URLQueryItem(name: "oauth_nonce", value: UUID().uuidString),
      URLQueryItem(name: "oauth_signature_method", value: "HMAC-SHA1"),
      URLQueryItem(name: "oauth_timestamp", value: String(Int(Date().timeIntervalSince1970))),
      URLQueryItem(name: "oauth_version", value: "1.0")
    ]
    
    let signature = oAuthSignature(httpMethod: request.httpMethod,
                                   baseURLString: request.baseURLString,
                                   parameters: parameters,
                                   consumerSecret: request.consumerSecret,
                                   oAuthTokenSecret: temporaryCredentials.requestTokenSecret)
    
    parameters.append(URLQueryItem(name: "oauth_signature", value: signature))
    
    var urlRequest = URLRequest(url: baseURL)
    urlRequest.httpMethod = request.httpMethod
    urlRequest.setValue(oAuthAuthorizationHeader(parameters: parameters),
                        forHTTPHeaderField: "Authorization")
    
    return
      URLSession.shared.dataTaskPublisher(for: urlRequest)
      .tryMap { data, response -> (TokenCredentials, User) in
        guard let response = response as? HTTPURLResponse
        else { throw OAuthError.unknown }
        
        guard response.statusCode == 200
        else { throw OAuthError.httpURLResponse(response.statusCode) }
        
        guard let parameterString = String(data: data, encoding: .utf8)
        else { throw OAuthError.cannotDecodeRawData }
        
        if let parameters = parameterString.urlQueryItems {
          guard let oAuthToken = parameters.value(for: "oauth_token"),
                let oAuthTokenSecret = parameters.value(for: "oauth_token_secret"),
                let userID = parameters.value(for: "user_id"),
                let screenName = parameters.value(for: "screen_name")
          else {
            throw OAuthError.unexpectedResponse
          }
          
          return (TokenCredentials(accessToken: oAuthToken,
                                   accessTokenSecret: oAuthTokenSecret),
                  User(ID: userID,
                       screenName: screenName))
        } else {
          throw OAuthError.cannotParseResponse
        }
      }
      .mapError { error -> OAuthError in
        switch (error) {
        case let oAuthError as OAuthError:
          return oAuthError
        default:
          return OAuthError.unknown
        }
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}
