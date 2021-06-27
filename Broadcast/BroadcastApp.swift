//
//  BroadcastApp.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

@main
struct BroadcastApp: App {
  @StateObject var themeHelper = ThemeHelper()
  @StateObject var twitterClient = TwitterClient()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(twitterClient)
        .environmentObject(themeHelper)
        .accentColor(themeHelper.color)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
          twitterClient.revalidateAccount()
        }
    }
  }
}
