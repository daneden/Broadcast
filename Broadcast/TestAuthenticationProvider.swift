//
//  TestAuthenticationProvider.swift
//  Broadcast
//
//  Created by Daniel Eden on 10/01/2022.
//

import Foundation
import AuthenticationServices
import Combine

class AuthenticationProvider: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  func requestAuthentication() async {
    let creds = TwitterClient.ClientCredentials.self
    
    guard let callbackURL = creds.callbackURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
      return
    }
    
    var requestTokenComponents = URLComponents()
    
    requestTokenComponents.scheme = "https"
    requestTokenComponents.host = "api.twitter.com"
    requestTokenComponents.path = "/2/oauth/request_token"
    requestTokenComponents.queryItems = [
      URLQueryItem(name: "oauth_callback", value: callbackURL)
    ]
    
    guard let requestTokenURL = requestTokenComponents.url else {
      return
    }
    
    var requestTokenRequest = URLRequest(url: requestTokenURL)
    
    requestTokenRequest.httpMethod = "POST"
    
    let clientKey = creds.apiKey
    let clientSecret = creds.apiSecret
    let requestTokenAuthorizationHeader = """
OAuth
oauth_consumer_key="\(clientKey)"
"""
    
    requestTokenRequest.setValue("", forHTTPHeaderField: "Authorization")
    
    do {
      let (requestTokenData, _) = try await URLSession.shared.data(for: requestTokenRequest)
      
      let decoded = try JSONDecoder().decode(String.self, from: requestTokenData)
      
      print(decoded)
    } catch {
      print(error.localizedDescription)
    }
  }
}
