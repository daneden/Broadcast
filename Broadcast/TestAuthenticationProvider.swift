//
//  TestAuthenticationProvider.swift
//  Broadcast
//
//  Created by Daniel Eden on 10/01/2022.
//

import Foundation
import AuthenticationServices
import Combine
import CommonCrypto

class AuthenticationProvider: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  func requestAuthentication() async {
    let creds = TwitterClient.ClientCredentials.self
    let callback = creds.callbackURL.absoluteString
    
    var urlRequest = URLRequest(url: URL(string: "https://api.twitter.com/oauth/request_token")!)
    
    urlRequest.oAuthSign(method: "POST", urlFormParameters: ["oauth_callback" : callback], consumerCredentials: (key: creds.apiKey, secret: creds.apiSecret))
    
    var oauthToken: String = ""
    var oauthTokenSecret: String = ""
    
    do {
      let (requestTokenData, _) = try await URLSession.shared.data(for: urlRequest)
      
      guard let response = String(data: requestTokenData, encoding: .utf8)?.urlQueryStringParameters,
      let token = response["oauth_token"],
      let tokenSecret = response["oauth_token_secret"] else {
        return
      }
      
      oauthToken = token
      oauthTokenSecret = tokenSecret
    } catch {
      print(error.localizedDescription)
    }
    
    let authURL = URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(oauthToken)")!
    
    let authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "https") { (url, error) in
      if let error = error {
        print(error.localizedDescription)
      } else if let url = url {
        print(url)
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
