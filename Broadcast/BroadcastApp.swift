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
      GeometryReader { geom in
        ZStack(alignment: .top) {
          ContentView()
            .environmentObject(twitterClient)
            .environmentObject(themeHelper)
            .accentColor(themeHelper.color)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
              twitterClient.revalidateAccount()
            }
          
          VisualEffectView(effect: UIBlurEffect(style: .regular))
            .frame(height: geom.safeAreaInsets.top)
            .ignoresSafeArea(.all, edges: .top)
        }
      }
    }
  }
}
