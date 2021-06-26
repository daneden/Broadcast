//
//  BroadcastApp.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

@main
struct BroadcastApp: App {
  @StateObject var twitterAPI = TwitterAPI()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(twitterAPI)
        .onOpenURL { url in
          guard let urlScheme = url.scheme,
                let callbackURL = URL(string: "\(TwitterAPI.ClientCredentials.CallbackURLScheme)://"),
                let callbackURLScheme = callbackURL.scheme
          else { return }
          
          guard urlScheme.caseInsensitiveCompare(callbackURLScheme) == .orderedSame
          else { return }
          
          twitterAPI.onOAuthRedirect.send(url)
        }
    }
  }
}
